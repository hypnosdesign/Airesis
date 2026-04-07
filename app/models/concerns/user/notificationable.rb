# Gestisce le preferenze di notifica dell'utente e l'accesso agli alert ricevuti.
#
# Le preferenze sono memorizzate come record nelle tabelle `blocked_alerts` e `blocked_emails`:
# - `blocked_notifications` — tipi di notifica disattivati nell'app (nessun alert in-app)
# - `blocked_email_notifications` — tipi di notifica per cui non si vuole l'email
#
# Al momento della registrazione, alcuni tipi di notifica rumorosi vengono bloccati di default
# tramite `init_notifications` per evitare spam al nuovo utente.
module User::Notificationable
  extend ActiveSupport::Concern

  included do
    has_many :notifications, through: :alerts, class_name: 'Notification'
    # Ordinati per created_at DESC: il pannello notifiche mostra le più recenti in cima.
    has_many :alerts, -> { order('alerts.created_at DESC') }, class_name: 'Alert'
    has_many :unread_alerts, -> { where 'alerts.checked = false' }, class_name: 'Alert'
    has_many :blocked_alerts, inverse_of: :user, dependent: :destroy
    has_many :blocked_emails, inverse_of: :user, dependent: :destroy
    has_many :blocked_notifications, through: :blocked_alerts, class_name: 'NotificationType', source: :notification_type
    has_many :blocked_email_notifications, through: :blocked_emails, class_name: 'NotificationType', source: :notification_type
  end

  # Blocca di default i tipi di notifica ad alto volume per i nuovi utenti.
  # I tipi bloccati di default sono:
  # - NEW_VALUTATION_MINE — ranking sulla propria proposta (molto frequente)
  # - NEW_VALUTATION      — ranking su proposte altrui seguite
  # - NEW_PUBLIC_EVENTS   — nuovi eventi pubblici
  # - NEW_PUBLIC_PROPOSALS — nuove proposte pubbliche
  #
  # Usa `build` (non `create`) per partecipare alla transazione del before_create.
  #
  # @return [void]
  def init_notifications
    blocked_alerts.build(notification_type_id: NotificationType::NEW_VALUTATION_MINE)
    blocked_alerts.build(notification_type_id: NotificationType::NEW_VALUTATION)
    blocked_alerts.build(notification_type_id: NotificationType::NEW_PUBLIC_EVENTS)
    blocked_alerts.build(notification_type_id: NotificationType::NEW_PUBLIC_PROPOSALS)
  end
end
