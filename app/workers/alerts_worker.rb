# worker to create alerts
class AlertsWorker < ApplicationJob
  queue_as :high_priority
  retry_on StandardError, attempts: 2

  def perform(attributes)
    Alert.create(attributes.merge(jid: job_id))
  end
end
