# Gestisce il profilo visibile dell'utente: avatar, nome, confini di interesse, tutorial, geocoding.
#
# I confini di interesse (`interest_borders`) determinano quali proposte e gruppi
# vengono mostrati nella homepage dell'utente e nei portlet territoriali.
# `derived_interest_borders_tokens` è un array PostgreSQL che include il territorio
# scelto E tutti i suoi antenati (comune → provincia → regione → nazione → continente).
module User::Profileable
  extend ActiveSupport::Concern

  included do
    has_many :meeting_participations, dependent: :destroy
    has_many :user_borders, class_name: 'UserBorder'
    has_many :interest_borders, through: :user_borders, class_name: 'InterestBorder'
    belongs_to :image, class_name: 'Image', foreign_key: :image_id, optional: true
    # `locale` è la lingua scelta dall'utente; `original_locale` è quella rilevata al momento della registrazione.
    belongs_to :locale, class_name: 'SysLocale', inverse_of: :users, foreign_key: 'sys_locale_id', optional: true
    belongs_to :original_locale, class_name: 'SysLocale', inverse_of: :original_users, foreign_key: 'original_sys_locale_id', optional: true

    has_many :tutorial_assignees, dependent: :destroy
    has_many :tutorials, through: :tutorial_assignees, class_name: 'Tutorial', source: :tutorial
    has_many :tutorial_progresses, dependent: :destroy
    # Tutorial non ancora completati: mostrati nel pannello onboarding.
    has_many :todo_tutorial_assignees, -> { where('tutorial_assignees.completed = false') }, class_name: 'TutorialAssignee'
    has_many :todo_tutorials, through: :todo_tutorial_assignees, class_name: 'Tutorial', source: :tutorial

    has_many :events
  end

  # @return [String] nome e cognome concatenati
  def fullname
    "#{name} #{surname}"
  end

  # URL-friendly per i link al profilo: usa ID + slug del nome per i permalink.
  # I caratteri non ASCII vengono rimossi per compatibilità URL.
  #
  # @return [String] es. "42-mario-rossi"
  def to_param
    "#{id}-#{fullname.downcase.gsub(/[^a-zA-Z0-9]+/, '-').gsub(/-{2,}/, '-').gsub(/^-|-$/, '')}"
  end

  # @return [String] fullname (usato da Rails nei select/display automatici)
  def to_s
    fullname
  end

  # URL dell'immagine profilo con fallback progressivo:
  # 1. Avatar Active Storage (caricato dall'utente)
  # 2. Gravatar basato sull'email (automatico, nessuna configurazione richiesta)
  # 3. Stringa vuota (la view deve gestire il caso "nessun avatar")
  #
  # Il metodo funziona anche se chiamato su un oggetto che ha una relazione `user`
  # (es. `ProposalNickname` — usa `self.user` in quel caso).
  #
  # @param size [Integer] dimensione in pixel per Gravatar (default: 80)
  # @return [String] URL relativo (Active Storage) o assoluto (Gravatar) o stringa vuota
  def user_image_url(size = 80, _params = {})
    user = respond_to?(:user) ? self.user : self

    if user.avatar.attached?
      Rails.application.routes.url_helpers.rails_blob_path(user.avatar, only_path: true)
    elsif user.email.present?
      require 'digest/md5'
      hash = Digest::MD5.hexdigest(user.email.downcase)
      "https://www.gravatar.com/avatar/#{hash}?s=#{size}"
    else
      ''
    end
  end

  # Determina il fuso orario dell'utente dal suo ultimo IP di accesso.
  # Chiamato da `GeocodeUser` job 5 secondi dopo la registrazione (IP non sempre disponibile subito).
  # Gli errori di geocoding o timezone vengono ignorati silenziosamente.
  #
  # @return [void]
  def geocode
    @search = Geocoder.search(last_sign_in_ip)
    unless @search.empty?
      @latlon = [@search[0].latitude, @search[0].longitude]
      @zone = begin
                Timezone::Zone.new latlon: @latlon
              rescue StandardError
                nil # il fuso orario non è critico: l'utente può impostarlo manualmente
              end
      update(time_zone: @zone.active_support_time_zone) if @zone
    end
  end

  # Assegna tutti i tutorial disponibili al nuovo utente e schedula il geocoding.
  # Il delay di 5 secondi sul geocoding dà tempo alla sessione di registrarsi prima che il job venga eseguito.
  # Chiamato da `after_create` in `User`.
  #
  # @return [void]
  def assign_tutorials
    Tutorial.all.find_each do |tutorial|
      assign_tutorial(self, tutorial)
    end
    GeocodeUser.set(wait: 5.seconds).perform_later(id)
  end

  # Sincronizza i confini di interesse dell'utente dal token CSV del form.
  # Ricostruisce `derived_interest_borders_tokens` risalendo la gerarchia geografica.
  # Chiamato sia al create (in `init`) che all'update (in `before_update_populate`).
  # Usa `user_borders.build` invece di `create` per partecipare alla transazione del record principale.
  #
  # @return [void]
  def update_borders
    return unless interest_borders_tokens

    interest_borders_tokens.split(',').each do |border|
      ftype = border[0, 1] # tipo di territorio: primo carattere del token
      fid = border[2..]    # ID del territorio
      found = InterestBorder.table_element(border)
      next unless found

      # Risale la gerarchia geografica per popolare i token derivati (usati nei filtri portlet)
      derived_row = found
      while derived_row
        self.derived_interest_borders_tokens |= [InterestBorder.to_key(derived_row)]
        derived_row = derived_row.parent
      end

      interest_b = InterestBorder.find_or_create_by(territory_type: InterestBorder::I_TYPE_MAP[ftype],
                                                    territory_id: fid)
      user_borders.build(interest_border_id: interest_b.id)
    end
  end
end
