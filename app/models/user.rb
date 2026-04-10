require 'digest/sha1'

# Modello centrale della piattaforma: rappresenta un utente registrato.
#
# La logica è suddivisa in concern tematici per mantenerla navigabile:
# - {User::Authenticatable} — OAuth, token API, social login
# - {User::Proposable}      — proposte, commenti, ranking
# - {User::Groupable}       — gruppi, ruoli, aree
# - {User::Socializable}    — blog, follower, commenti eventi
# - {User::Forumable}       — accesso al forum integrato (Frm)
# - {User::Notificationable}— alert, preferenze notifiche email
# - {User::Profileable}     — avatar, confini di interesse, tutorial, geocoding
#
# L'autenticazione supporta Devise (email/password) e OmniAuth (Facebook, Google, Twitter).
# L'autorizzazione usa CanCanCan: delegare sempre a `can?` / `cannot?`.
# Il token API (`authentication_token`) è gestito da `has_secure_token` (Rails native).
class User < ApplicationRecord
  has_secure_token :authentication_token

  devise :database_authenticatable, :registerable, :confirmable, :omniauthable,
         :blockable, :recoverable, :rememberable, :trackable, :validatable, :traceable

  include User::Authenticatable
  include User::Proposable
  include User::Groupable
  include User::Socializable
  include User::Forumable
  include User::Notificationable
  include User::Profileable
  include TutorialAssigneesHelper

  # `image_url` è un attributo virtuale usato per importare avatar da URL OAuth.
  # `interest_borders_tokens` è la stringa CSV dei token territoriali dal form.
  attr_accessor :image_url, :accept_conditions, :accept_privacy, :interest_borders_tokens

  # == Validations

  # `name_regex` in AuthenticationModule valida i caratteri Unicode per nomi internazionali.
  validates :name, presence: true, length: { maximum: 50 }, format: { with: AuthenticationModule.name_regex, allow_nil: true }
  validates :surname, length: { maximum: 50 }, format: { with: AuthenticationModule.name_regex, allow_nil: true }
  validates :password, confirmation: true
  validates :accept_conditions, acceptance: { message: ->(_obj, _opts) { I18n.t('activerecord.errors.messages.TOS') } }
  validates :accept_privacy, acceptance: { message: ->(_obj, _opts) { I18n.t('activerecord.errors.messages.privacy') } }

  enum :user_type_id, { administrator: 1, moderator: 2, authenticated: 3 }, prefix: true

  # == Attachments

  has_one_attached :avatar

  validates :avatar, content_type: ['image/jpeg', 'image/png', 'image/gif'],
                     size: { less_than: UPLOAD_LIMIT_IMAGES.bytes }

  # == Scopes

  scope :all_except, ->(user) { where.not(id: user) }
  scope :blocked, -> { where(blocked: true) }
  scope :unblocked, -> { where(blocked: false) }
  scope :confirmed, -> { where 'confirmed_at is not null' }
  scope :unconfirmed, -> { where 'confirmed_at is null' }
  # Stima degli utenti attivi: percentuale configurabile via ENV['ACTIVE_USERS_PERCENTAGE'].
  # Usato dal calcolo delle `valutations` dei quorum per non richiedere il 100% degli iscritti.
  scope :count_active, -> { unblocked.count.to_f * (ENV['ACTIVE_USERS_PERCENTAGE'].to_f / 100.0) }
  scope :autocomplete, ->(term) { where('lower(users.name) LIKE :term or lower(users.surname) LIKE :term', term: "%#{term.to_s.downcase}%").order('users.surname desc, users.name desc').limit(10) }
  scope :by_interest_borders, ->(ib) { where('users.derived_interest_borders_tokens @> ARRAY[?]::varchar[]', ib) }

  # == Callbacks

  before_create :init
  after_create :assign_tutorials
  before_update :before_update_populate

  # == Instance Methods

  # Scarica e allega l'avatar dall'URL OAuth (Facebook/Google).
  # Gli errori di rete o URL non validi vengono silenziati: l'utente può caricare l'avatar manualmente.
  #
  # @param url [String] URL pubblico dell'immagine del provider OAuth
  # @return [void]
  def avatar_url=(url)
    return if url.blank?

    uri = URI.parse(url)
    return unless uri.is_a?(URI::HTTPS) || uri.is_a?(URI::HTTP)
    return unless uri.host.present?

    io = uri.open(read_timeout: 5, open_timeout: 5)
    avatar.attach(io: io, filename: File.basename(uri.path).presence || 'avatar.jpg')
  rescue StandardError
    # Ignorato: avatar non disponibile non deve bloccare la creazione dell'account
  end

  # Twitter non fornisce email → l'email non è obbligatoria per gli account Twitter.
  # Per tutti gli altri provider (email/password, Facebook, Google) l'email è richiesta.
  #
  # @return [Boolean]
  def email_required?
    super && !has_oauth_provider_without_email
  end

  # Inizializza i valori di default del nuovo utente prima del salvataggio.
  # Chiamato da `before_create`: i confini di interesse e le notifiche bloccate di default
  # vengono configurati qui prima che il record esista in DB.
  def init
    self.rank ||= 0
    self.receive_messages = true
    self.receive_newsletter = true
    update_borders
    init_notifications
  end

  # @return [Boolean] true se l'utente è amministratore globale della piattaforma
  def admin?
    user_type_id_administrator?
  end

  # I moderatori includono anche gli amministratori — un admin può fare tutto ciò che fa un moderatore.
  #
  # @return [Boolean]
  def moderator?
    admin? || user_type_id_moderator?
  end

  # Verifica se l'oggetto appartiene a questo utente.
  # Supporta oggetti con `user_id` (FK diretta) o con relazione `has_many :users`.
  #
  # @param object [ApplicationRecord, nil] oggetto da verificare
  # @return [Boolean]
  def is_mine?(object)
    return false unless object
    if object.respond_to?('user_id')
      object.user_id == id
    elsif object.respond_to?('users')
      object.users.exists?(id: id)
    else
      false
    end
  end

  # ID codificato in Base64 per uso in contesti non sicuri (es. link email).
  # Non usare per sicurezza critica: Base64 è reversibile senza chiave.
  #
  # @return [String]
  def encoded_id
    Base64.encode64(id.to_s)
  end

  # @param id [String] ID codificato in Base64
  # @return [String] ID originale come stringa
  def self.decode_id(id)
    Base64.decode64(id)
  end

  # URL del percorso Active Storage dell'avatar (path relativo, non URL assoluto).
  # Restituisce nil se nessun avatar è allegato — le view devono gestire questo caso.
  #
  # @return [String, nil]
  def image_url
    avatar.attached? ? Rails.application.routes.url_helpers.rails_blob_path(avatar, only_path: true) : nil
  end

  # Delega `can?` e `cannot?` a un'istanza di `Ability` (CanCanCan) memoizzata.
  # L'ability è costruita una volta per request e non cambia nel ciclo di vita dell'oggetto.
  delegate :can?, :cannot?, to: :ability

  # @return [Ability] istanza dell'ability CanCanCan per questo utente
  def ability
    @ability ||= Ability.new(self)
  end

  # Garantisce che il token API esista, generandolo se è vuoto.
  # Usato all'accesso via API per utenti creati prima dell'introduzione del token.
  #
  # @return [void]
  def ensure_authentication_token!
    regenerate_authentication_token if authentication_token.blank?
    save!
  end

  # Invalida il token API corrente e ne genera uno nuovo.
  # Chiamare dopo una compromissione sospetta del token.
  #
  # @return [void]
  def reset_authentication_token!
    regenerate_authentication_token
    save!
  end

  private

  def reconfirmation_required?
    self.class.reconfirmable && @reconfirmation_required
  end

  # Ricostruisce i confini di interesse dell'utente ad ogni update.
  # I `user_borders` vengono distrutti e ricreati perché il form invia sempre la lista completa.
  def before_update_populate
    user_borders.destroy_all
    update_borders
  end
end
