class NewsletterSender < ApplicationJob
  discard_on StandardError

  def perform(newsletter_id, user_ids)
    user_ids.each do |user_id|
      ResqueMailer.publish(newsletter_id, user_id).deliver_later
    end
  end
end
