class FixWorkers < ApplicationJob
  def perform(*_args)
    AlertJob.all.find_each do |alert_job|
      alert_job.destroy unless alert_job.scheduled_in_queue?
    end
    EmailJob.all.find_each do |email_job|
      email_job.destroy unless email_job.scheduled_in_queue?
    end
  end
end
