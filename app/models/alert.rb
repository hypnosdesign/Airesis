# Una singola notifica inviata a un utente specifico.
#
# Il flusso di creazione è gestito da `NotificationSender`:
# - Se la notifica è cumulabile e ne esiste già una non letta → chiama `accumulate` sull'alert esistente
# - Altrimenti → crea un nuovo Alert e i callback `after_commit` inviano email e broadcast WebSocket
#
# Le `properties` dell'Alert si fondono con quelle della Notification tramite il `default_scope`
# (`notifications.properties || alerts.properties`), che genera la colonna virtuale `nproperties`.
# L'operatore `||` di PostgreSQL fa merge dei due jsonb, con priorità ai valori dell'alert.
class Alert < ApplicationRecord
  # == Associations

  belongs_to :user, class_name: 'User', foreign_key: :user_id
  belongs_to :notification, class_name: 'Notification', foreign_key: :notification_id
  belongs_to :trackable, polymorphic: true

  # `jid` è l'ID del job Solid Queue usato per trovare l'`AlertJob` in coda prima della creazione.
  attr_accessor :jid

  # Merge jsonb: `alerts.properties` sovrascrive `notifications.properties` in caso di chiavi duplicate.
  # Questo permette a ogni alert di personalizzare i dati della notifica (es. contatore cumulato).
  default_scope lambda {
    select('alerts.*, notifications.properties || alerts.properties as nproperties').
      joins(:notification)
  }

  has_one :notification_type, through: :notification
  has_one :notification_category, through: :notification_type
  has_one :email_job

  # == Callbacks

  before_create :set_counter
  before_create :continue?

  after_commit :send_email, on: :create
  after_commit :broadcast_notification, on: :create
  after_commit :complete_alert_job, on: :create

  def alert_job
    @alert_job ||= AlertJob.find_by(jid: jid)
  end

  # == Instance Methods

  # Restituisce le proprietà merged (notification + alert) come hash con accesso indifferente.
  # Il campo `count` è sempre un Integer (può essere stringa in jsonb).
  #
  # @return [HashWithIndifferentAccess]
  def data
    ret = nproperties.with_indifferent_access
    ret[:count] = ret[:count].to_i
    ret.symbolize_keys
  end

  def data=(data)
    self.properties = data
  end

  def email_subject
    group = data[:group]
    subject = group ? "[#{group}] " : ''
    subject + I18n.t(notification.email_subject_interpolation, **data)
  end

  def message
    I18n.t(notification.message_interpolation, **data)
  end

  def check!
    update(checked: true, checked_at: Time.zone.now)
  end

  def self.check_all
    update_all(checked: true, checked_at: Time.zone.now)
  end

  # Accumula una notifica aggiuntiva su questo alert esistente invece di crearne uno nuovo.
  # Usato da `NotificationSender` per le notifiche cumulabili (es. "X nuovi commenti").
  #
  # Logica email:
  # - Se l'email è ancora in coda → aggiorna il delay (`email_job.accumulate`)
  # - Se l'email è già stata inviata ma l'alert non è letto → manda una nuova email con delay aggiuntivo
  #
  # @return [void]
  def accumulate
    increase_count!
    if email_job.present? && email_job.scheduled_in_queue?
      # L'email non è ancora partita: aggiorna il timer per includere il nuovo evento
      email_job.accumulate
    else
      # L'email è già partita ma l'utente non ha letto l'alert: invia una nuova email con delay alert
      send_email(true)
    end
    broadcast_notification
  end

  def increase_count!
    properties_will_change!
    count = properties['count'] ? properties['count'].to_i : 1
    properties['count'] = count + 1
    save!
  end

  def soft_delete
    update!(deleted: true, deleted_at: Time.zone.now)
  end

  def self.soft_delete_all
    update_all(deleted: true, deleted_at: Time.zone.now)
  end

  def trigger_user
    @trigger_user ||= User.find(nproperties['user_id'])
  end

  # URL dell'immagine da mostrare nella notifica.
  # Se la notifica ha un utente scatenante (`user_id`):
  # - Per le proposte usa l'avatar anonimo (rispetta l'anonimato della proposta)
  # - Per altri trackable usa l'avatar standard dell'utente
  # Se non c'è utente scatenante (es. notifica di sistema) usa l'icona della categoria.
  #
  # @return [String] URL assoluto dell'immagine
  def image_url
    if nproperties['user_id'].present?
      if trackable.instance_of? Proposal
        trackable.user_avatar_url(trigger_user) # rispetta l'anonimato della proposta
      else
        trigger_user.user_image_url
      end
    else
      ActionController::Base.helpers.asset_path("notification_categories/#{notification_category.short.downcase}.png")
    end
  end

  protected

  # Blocca la creazione dell'alert se il job associato (`AlertJob`) è stato cancellato.
  # Usato come `before_create` per prevenire alert "fantasma" da job già annullati.
  #
  # @return [Boolean] false → blocca il create (come `throw :abort`)
  def continue?
    alert_job.nil? || !alert_job.canceled?
  end

  # Inizializza il contatore cumulato partendo dall'`AlertJob` se disponibile.
  # L'`AlertJob` tiene il conteggio degli eventi accumulati prima che l'alert venga creato.
  def set_counter
    properties_will_change!
    properties['count'] = alert_job ? alert_job.accumulated_count : 1
  end

  # Schedula l'invio email con delay configurato per tipo di notifica.
  # `add_alert_delay = true` aggiunge un ulteriore delay per le email di accumulo
  # (dà tempo all'utente di leggere prima di ricevere l'ennesima email).
  #
  # @param add_alert_delay [Boolean] aggiunge `alert_delay` al delay base (default: false)
  # @return [void]
  def send_email(add_alert_delay = false)
    return if checked?           # l'utente ha già letto l'alert
    return if user.blocked?      # utente sospeso
    return if user.blocked_email_notifications.include? notification_type # preferenza utente
    return if user.email.blank?  # utente senza email (social login senza conferma)

    delay = notification.notification_type.email_delay
    delay += notification.notification_type.alert_delay if add_alert_delay
    job = EmailsWorker.set(wait: delay.minutes).perform_later(id)
    EmailJob.create(alert: self, jid: job.job_id)
  end

  # Invia un aggiornamento real-time al pannello notifiche dell'utente via Action Cable.
  # Usa `broadcast_replace_to` per aggiornare solo il flash container senza ricaricare la pagina.
  # Il rescue previene che errori WebSocket rompano il flusso di creazione dell'alert.
  def broadcast_notification
    Turbo::StreamsChannel.broadcast_replace_to(
      "notifications_#{user.id}",
      target: "flash-container",
      partial: "layouts/flash",
      locals: { flash: { notice: message } }
    )
    # Aggiorna il badge count in real-time: +1 perché l'alert corrente è appena creato
    # ma la query unread_alerts potrebbe non includerlo ancora (dipende dal timing after_commit)
    unread_count = Alert.unscoped.where(user_id: user.id, checked: false).count
    badge_html = if unread_count > 0
                   "<span id='notification_badge' class='indicator-item badge badge-error badge-xs'>#{unread_count}</span>"
                 else
                   "<span id='notification_badge' class='indicator-item badge badge-error badge-xs hidden'></span>"
                 end
    Turbo::StreamsChannel.broadcast_replace_to(
      "notifications_#{user.id}",
      target: "notification_badge",
      html: badge_html
    )
  rescue StandardError => e
    Rails.logger.error "Error broadcasting notification: #{e.message}"
  end

  # Distrugge l'`AlertJob` dopo che l'alert è stato creato con successo.
  # L'AlertJob era un segnaposto in coda; ora che l'alert esiste in DB non è più necessario.
  def complete_alert_job
    alert_job&.destroy
  end
end
