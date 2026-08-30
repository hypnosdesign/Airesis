class Newsletter < ApplicationRecord
  RECEIVERS = %w[admin all not_confirmed test].freeze

  validates :subject, presence: true, length: { maximum: 255 }
  validates :body, presence: true, length: { maximum: 1.megabyte }

  attr_accessor :receiver

  def publish(receiver:, test_user_id:)
    user_ids = recipient_ids(receiver: receiver, test_user_id: test_user_id)
    user_ids.each_slice(500) do |batch|
      NewsletterSender.set(wait: 5.seconds).perform_later(id, batch)
    end
    user_ids.size
  end

  def recipient_count(receiver:, test_user_id:)
    recipients(receiver: receiver, test_user_id: test_user_id).count
  end

  private

  def recipient_ids(receiver:, test_user_id:)
    recipients(receiver: receiver, test_user_id: test_user_id).pluck(:id)
  end

  def recipients(receiver:, test_user_id:)
    deliverable = User.where(blocked: false).where.not(email: [nil, ''])

    case receiver.to_s
    when 'all'
      deliverable.confirmed.where(receive_newsletter: true)
    when 'not_confirmed'
      deliverable.unconfirmed
    when 'admin'
      deliverable.user_type_id_administrator
    when 'test'
      deliverable.where(id: User.find(test_user_id).id)
    else
      raise ArgumentError, 'Unsupported newsletter receiver'
    end
  end
end
