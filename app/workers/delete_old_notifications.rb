class DeleteOldNotifications < ApplicationJob
  BATCH_SIZE = 500

  def perform
    expired_count = destroy_in_batches(Notification.where(created_at: ...6.months.ago))
    unread_ids = Alert.unscoped.where(checked: false).select(:notification_id)
    stale_read = Notification.where(created_at: ...1.month.ago).where.not(id: unread_ids)
    read_count = destroy_in_batches(stale_read)

    count = expired_count + read_count
    message = "Cancellate #{expired_count} notifiche oltre la retention assoluta e #{read_count} notifiche già lette."
    ResqueMailer.admin_message(message).deliver_later
    count
  end

  private

  def destroy_in_batches(scope)
    scope.in_batches(of: BATCH_SIZE).sum { |batch| batch.destroy_all.size }
  end
end
