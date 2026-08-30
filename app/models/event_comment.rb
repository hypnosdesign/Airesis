class EventComment < ApplicationRecord
  MAX_BODY_LENGTH = 2_500

  belongs_to :user
  belongs_to :event
  belongs_to :comment, class_name: 'EventComment', foreign_key: :parent_event_comment_id, optional: true

  has_many :comments,
           class_name: 'EventComment',
           foreign_key: :parent_event_comment_id,
           inverse_of: :comment,
           dependent: :destroy

  has_many :likes, class_name: 'EventCommentLike', foreign_key: :event_comment_id, dependent: :destroy
  has_many :likers, class_name: 'User', through: :likes, source: :user

  validates :body, presence: true, length: { maximum: MAX_BODY_LENGTH }

  attr_accessor :collapsed

  def after_initialize
    @collapsed = false
  end

  def formatted_created_at
    created_at.strftime('%m/%d/%Y alle %I:%M%p')
  end

  def parsed_body
    body
  end

  # Used to set more tracking for akismet
  def request=(request)
    self.user_ip = request.remote_ip
    self.user_agent = request.env['HTTP_USER_AGENT']
    self.referrer = request.env['HTTP_REFERER']
  end
end
