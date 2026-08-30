module Frm
  class Topic < FrmTable
    include Frm::Concerns::Viewable
    include Taggable
    include Workflow

    MODERATION_OPTIONS = %w[approve spam].freeze

    workflow_column :state
    workflow do
      state :pending_review do
        event :spam, transitions_to: :spam
        event :approve, transitions_to: :approved
      end
      state :spam
      state :approved do
        event :approve, transitions_to: :approved
      end
    end

    attr_accessor :moderation_option

    extend FriendlyId
    friendly_id :subject, use: :scoped, scope: :forum

    belongs_to :forum, class_name: 'Frm::Forum'
    belongs_to :user, class_name: 'User'
    has_many :subscriptions
    has_many :posts, -> { order 'frm_posts.created_at ASC' }, dependent: :destroy, inverse_of: :topic

    has_many :topic_tags, dependent: :destroy, foreign_key: 'frm_topic_id'
    has_many :tags, through: :topic_tags, class_name: 'Tag'

    has_many :topic_proposals, class_name: 'Frm::TopicProposal', foreign_key: 'topic_id'
    has_many :proposals, class_name: '::Proposal', through: :topic_proposals

    scope :by_pinned, -> { order('frm_topics.pinned DESC').order('frm_topics.id') }
    scope :by_most_recent_post, -> { order('frm_topics.last_post_at DESC').order('frm_topics.id') }
    scope :by_pinned_or_most_recent_post, -> { order('frm_topics.pinned DESC').by_most_recent_post }
    scope :pending_review, -> { where(state: 'pending_review') }
    scope :approved, -> { where(state: 'approved') }
    accepts_nested_attributes_for :posts

    validates :subject, presence: true
    validates :user, presence: true

    before_validation :set_first_post_user, on: :create
    before_validation :apply_default_moderation_state, on: :create
    after_update :approve_user_and_posts, if: :saved_change_to_state?
    after_create :subscribe_poster
    after_commit :send_notifications, on: :create

    class << self
      def visible(user = nil)
        user ? where('hidden = false or user_id = ?', user.id) : where(hidden: false)
      end

      def approved_or_pending_review_for(user)
        if user
          where('frm_topics.state = ? OR (frm_topics.state = ? AND frm_topics.user_id = ?)',
                'approved', 'pending_review', user.id)
        else
          approved
        end
      end
    end

    def to_s
      subject
    end

    # Cannot use method name lock! because it's reserved by AR::Base
    def lock_topic!
      update_attribute(:locked, true)
    end

    def unlock_topic!
      update_attribute(:locked, false)
    end

    # Provide convenience methods for pinning, unpinning a topic
    def pin!
      update_attribute(:pinned, true)
    end

    def unpin!
      update_attribute(:pinned, false)
    end

    def moderate!(option)
      normalized_option = option.to_s
      raise ArgumentError, 'Unsupported moderation option' unless MODERATION_OPTIONS.include?(normalized_option)

      public_send("#{normalized_option}!")
    end

    # Workflow 4.x does not read the custom Rails 8 state column reliably.
    # Keep UI predicates tied to the persisted source of truth.
    def pending_review?
      state == 'pending_review'
    end

    def approved?
      state == 'approved'
    end

    def spam?
      state == 'spam'
    end

    # workflow 4.x does not persist its custom state column under Rails 8.
    def approve!
      update!(state: 'approved')
    end

    def spam!
      update!(state: 'spam')
    end

    # A Topic cannot be replied to if it's locked.
    def can_be_replied_to?
      !locked?
    end

    def subscribe_poster
      subscribe_user(user_id)
    end

    def subscribe_user(subscriber_id)
      return if !subscriber_id || subscriber?(subscriber_id)

      subscriptions.create!(subscriber_id: subscriber_id)
    end

    def unsubscribe_user(subscriber_id)
      subscriptions_for(subscriber_id).destroy_all
    end

    def subscriber?(subscriber_id)
      subscriptions_for(subscriber_id).any?
    end

    def subscription_for(subscriber_id)
      subscriptions_for(subscriber_id).first
    end

    def subscriptions_for(subscriber_id)
      subscriptions.where(subscriber_id: subscriber_id)
    end

    def last_page
      (posts.count.to_f / TOPICS_PER_PAGE).ceil
    end

    def should_generate_new_friendly_id?
      subject_changed?
    end

    protected

    def set_first_post_user
      post = posts.first
      post.user = user
      self.token = loop do
        random_token = SecureRandom.urlsafe_base64(16, false)
        break random_token unless Post.where(token: random_token).exists?
      end
    end

    def apply_default_moderation_state
      self.state = 'approved' if state.blank? || state == 'pending_review'
    end

    def approve_user_and_posts
      return unless approved?

      first_post = posts.by_created_at.first
      first_post&.approve! unless first_post&.approved?
    end

    def send_notifications
      NotificationForumTopicCreate.perform_later(id) if approved?
    end
  end
end
