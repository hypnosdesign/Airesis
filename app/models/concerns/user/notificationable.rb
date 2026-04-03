module User::Notificationable
  extend ActiveSupport::Concern

  included do
    has_many :notifications, through: :alerts, class_name: 'Notification'
    has_many :alerts, -> { order('alerts.created_at DESC') }, class_name: 'Alert'
    has_many :unread_alerts, -> { where 'alerts.checked = false' }, class_name: 'Alert'
    has_many :blocked_alerts, inverse_of: :user, dependent: :destroy
    has_many :blocked_emails, inverse_of: :user, dependent: :destroy
    has_many :blocked_notifications, through: :blocked_alerts, class_name: 'NotificationType', source: :notification_type
    has_many :blocked_email_notifications, through: :blocked_emails, class_name: 'NotificationType', source: :notification_type
  end

  def init_notifications
    blocked_alerts.build(notification_type_id: NotificationType::NEW_VALUTATION_MINE)
    blocked_alerts.build(notification_type_id: NotificationType::NEW_VALUTATION)
    blocked_alerts.build(notification_type_id: NotificationType::NEW_PUBLIC_EVENTS)
    blocked_alerts.build(notification_type_id: NotificationType::NEW_PUBLIC_PROPOSALS)
  end
end
