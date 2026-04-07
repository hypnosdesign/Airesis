# Gestisce l'autenticazione OAuth e i provider di identità esterni (Facebook, Google, Twitter).
#
# Un utente può avere zero o più `Authentication` (uno per provider).
# Un account creato via email può collegare provider OAuth successivamente con `oauth_join`.
# Un account OAuth può accedere solo tramite il provider (nessuna password locale).
module User::Authenticatable
  extend ActiveSupport::Concern

  included do
    has_many :authentications, class_name: 'Authentication', dependent: :destroy
  end

  # @return [Boolean] true se l'utente ha almeno un provider OAuth collegato
  def from_identity_provider?
    authentications.any?
  end

  # @param provider_name [String] nome del provider (es. 'facebook', 'google_oauth2', 'twitter')
  # @return [Boolean]
  def has_provider?(provider_name)
    authentications.exists?(provider: provider_name)
  end

  # Costruisce (senza salvare) un record `Authentication` dal payload OAuth.
  # Il token è usato per chiamate API successive (es. Koala per Facebook).
  #
  # @param access_token [Hash] payload OAuth2 come restituito da OmniAuth
  # @return [Authentication] record non ancora salvato
  def build_authentication_provider(access_token)
    authentications.build(
      provider: access_token['provider'],
      uid: access_token['uid'],
      token: access_token.dig('credentials', 'token')
    )
  end

  # Client API Facebook tramite Koala.
  # Restituisce nil se l'utente non ha un'autenticazione Facebook o il token è scaduto.
  #
  # @return [Koala::Facebook::API, nil]
  def facebook
    @fb_user ||= begin
                   Koala::Facebook::API.new(authentications.find_by(provider: Authentication::FACEBOOK).try(:token))
                 rescue StandardError
                   nil
                 end
  end

  # Collega un provider OAuth a un account esistente (email/password o altro OAuth).
  # Usato quando l'utente è già loggato e vuole aggiungere un metodo di accesso alternativo.
  # L'intera operazione è in transazione: se fallisce non resta nessuna autenticazione parziale.
  #
  # @param oauth_data [OmniAuth::AuthHash] payload OAuth come ricevuto da OmniAuth
  # @return [void]
  # @raise [ActiveRecord::RecordInvalid] se il salvataggio fallisce
  def oauth_join(oauth_data)
    oauth_data_parser = OauthDataParser.new(oauth_data)
    provider = oauth_data_parser.provider
    raw_info = oauth_data_parser.raw_info
    user_info = oauth_data_parser.user_info

    self.class.transaction do
      build_authentication_provider(oauth_data)
      self.email = user_info[:email] unless email # non sovrascrivere email esistente
      set_social_network_pages(provider, raw_info)
      save!
    end
  end

  # Salva gli URL dei profili social ottenuti dal payload OAuth.
  # Chiamato sia alla creazione account OAuth che al collegamento di un nuovo provider.
  #
  # @param provider [String] nome del provider
  # @param raw_info [Hash] dati grezzi del profilo come restituiti dal provider
  # @return [void]
  def set_social_network_pages(provider, raw_info)
    self.google_page_url = raw_info['profile'] if provider == Authentication::GOOGLE
    self.facebook_page_url = raw_info['link'] if provider == Authentication::FACEBOOK
  end

  # Costruisce l'URL del profilo Twitter dall'UID memorizzato (non dall'handle).
  # Twitter non espone l'handle nel token OAuth, ma l'UID è stabile anche dopo rinomina.
  #
  # @return [String, nil] URL del profilo Twitter o nil se non collegato
  def twitter_page_url
    auth = authentications.find_by(provider: Authentication::TWITTER)
    "https://twitter.com/intent/user?user_id=#{auth.uid}" if auth
  end

  # Impedisce il reset password per utenti bloccati.
  # Restituisce `:not_found` invece di `:blocked` per non rivelare lo stato dell'account.
  #
  # @return [Boolean] false se l'utente è bloccato
  def send_reset_password_instructions
    if blocked
      errors.add(:base, :not_found)
      return false
    end
    super
  end

  # Solo Twitter non fornisce email nel payload OAuth.
  # Gli account Twitter richiedono conferma email separata o possono operare senza.
  #
  # @return [Boolean]
  def has_oauth_provider_without_email
    has_provider?(Authentication::TWITTER)
  end

  class_methods do
    # Punto di ingresso per il callback OmniAuth: trova o crea un account.
    #
    # Logica di lookup:
    # 1. Cerca un'`Authentication` esistente per provider+uid → restituisce l'utente collegato
    # 2. Cerca un utente con la stessa email → collega il provider all'account esistente
    # 3. Crea un nuovo account OAuth
    #
    # @param oauth_data [OmniAuth::AuthHash] payload OAuth
    # @return [Array(User, Boolean, Boolean)] [utente, nuovo_login?, account_già_esisteva?]
    def find_or_create_for_oauth_provider(oauth_data)
      oauth_data_parser = OauthDataParser.new(oauth_data)
      provider = oauth_data_parser.provider
      uid = oauth_data_parser.uid
      user_info = oauth_data_parser.user_info

      auth = Authentication.find_by(provider: provider, uid: uid)
      if auth
        [auth.user, false, false]
      else
        # Se esiste già un utente con questa email, collega il provider senza creare un doppione
        user = user_info[:email] && User.find_by(email: user_info[:email])
        user ? [user, true, true] : [create_account_for_oauth(oauth_data), true, false]
      end
    end

    # Crea un nuovo account utente dal payload OAuth.
    # La password è casuale (non usata): l'utente accede solo via OAuth.
    # L'account viene confermato immediatamente (l'email è verificata dal provider).
    # Restituisce nil se il provider non fornisce un nome (non si può creare l'account).
    #
    # @param oauth_data [OmniAuth::AuthHash] payload OAuth
    # @return [User, nil] utente creato o nil se dati insufficienti
    def create_account_for_oauth(oauth_data)
      oauth_data_parser = OauthDataParser.new(oauth_data)
      provider = oauth_data_parser.provider
      raw_info = oauth_data_parser.raw_info
      user_info = oauth_data_parser.user_info

      return nil if user_info[:name].blank?

      user = User.new(
        name: user_info[:name],
        surname: user_info[:surname],
        password: Devise.friendly_token[0, 20], # password casuale: l'utente non la usa mai
        sex: user_info[:sex],
        email: user_info[:email]
      )

      user.tap do |u|
        u.avatar_url = user_info[:avatar_url]
        u.google_page_url = raw_info['profile'] if provider == Authentication::GOOGLE
        u.facebook_page_url = raw_info['link'] if provider == Authentication::FACEBOOK

        transaction do
          u.build_authentication_provider(oauth_data)
          u.sign_in_count = 0
          u.confirm          # email già verificata dal provider OAuth
          u.user_type_id = :authenticated
          u.save!
        end
      end
    end
  end
end
