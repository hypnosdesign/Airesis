# worker to create emails
class EmailsWorker < ApplicationJob
  queue_as :low_priority
  retry_on StandardError, attempts: 2

  def perform(alert_id)
    ResqueMailer.notification(alert_id).deliver_now
    EmailJob.find_by(jid: job_id)&.destroy
  end
end
