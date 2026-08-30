class NewsletterSender < ApplicationJob
  retry_on ActiveJob::EnqueueError, wait: :polynomially_longer, attempts: 5

  def perform(newsletter_id, user_ids)
    jobs = user_ids.uniq.map { |user_id| NewsletterDeliveryJob.new(newsletter_id, user_id) }
    ActiveJob.perform_all_later(*jobs)
  end
end
