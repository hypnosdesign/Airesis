class ApplicationJob < ActiveJob::Base
  # Sidekiq-compatible test helpers for specs using .jobs / .drain pattern
  def self.jobs
    ActiveJob::Base.queue_adapter.enqueued_jobs.select { |j| j[:job] == self }
  end

  def self.drain
    jobs_to_run = jobs.dup
    ActiveJob::Base.queue_adapter.enqueued_jobs.reject! { |j| j[:job] == self }
    jobs_to_run.each do |payload|
      # Deserialize with original job_id preserved (important for DB callbacks like complete_alert_job)
      job = new
      job.deserialize(payload.transform_keys(&:to_s))
      job.perform_now
    end
  end
end
