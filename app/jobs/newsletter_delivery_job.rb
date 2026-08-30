class NewsletterDeliveryJob < ApplicationJob
  queue_as :mailers

  retry_on StandardError, wait: :polynomially_longer, attempts: 5
  discard_on ActiveRecord::RecordNotFound

  def perform(newsletter_id, user_id)
    ResqueMailer.publish(newsletter_id, user_id).deliver_now
  end
end
