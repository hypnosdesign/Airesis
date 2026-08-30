class MeetingParticipation < ApplicationRecord
  MAX_GUESTS = 99
  RESPONSES = %w[Y N].freeze

  belongs_to :user, class_name: 'User', foreign_key: :user_id
  belongs_to :meeting, class_name: 'Meeting', foreign_key: :meeting_id

  delegate :event, to: :meeting

  validates :user_id, presence: true
  validates :user, uniqueness: { scope: :meeting }
  validates :meeting, presence: true
  validates :guests,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: MAX_GUESTS
            }
  validates :response, presence: true, inclusion: { in: RESPONSES }

  validates :comment, length: { maximum: 255 }

  def will_come?
    response == 'Y'
  end
end
