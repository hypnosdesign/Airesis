class DeleteOldNotifications < ApplicationJob
  def perform(*_args)
    count = 0
    deleted = Notification.where('created_at < ?', 6.months.ago).destroy_all
    count += deleted.count
    read = Notification.where("notifications.id not in (
                                              select n.id
                                              from notifications n
                                              join alerts ua
                                              on n.id = ua.notification_id
                                              where ua.checked = FALSE)
                                              and created_at < ?", 1.month.ago).destroy_all
    count += read.count
    count
  end
end
