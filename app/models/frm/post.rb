module Frm
  class Post < FrmTable
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

    # Used in the moderation tools partial
    attr_accessor :moderation_option

    belongs_to :topic, inverse_of: :posts
    belongs_to :user, class_name: 'User'
    belongs_to :reply_to, class_name: 'Post', optional: true

    has_many :replies, class_name: 'Post',
                       foreign_key: 'reply_to_id',
                       dependent: :nullify

    has_rich_text :text

    validates :text, presence: true
    validate :reply_to_belongs_to_topic

    delegate :forum, to: :topic

    delegate :group, to: :forum

    after_create :set_topic_last_post_at
    after_create :subscribe_replier
    before_validation :apply_default_moderation_state, on: :create

    before_create :populate_token

    after_save :email_topic_subscribers, if: proc { |p| p.approved? && !p.notified? }

    class << self
      def approved
        where(state: 'approved')
      end

      def approved_or_pending_review_for(user)
        if user
          where arel_table[:state].eq('approved').or(
            arel_table[:state].eq('pending_review').and(arel_table[:user_id].eq(user.id))
          )
        else
          approved
        end
      end

      def by_created_at
        order :created_at
      end

      def pending_review
        where state: 'pending_review'
      end

      def spam
        where state: 'spam'
      end

      def visible(user = nil)
        if user
          joins(:topic).where('frm_topics.hidden = false or frm_topics.user_id = ?', user.id)
        else
          joins(:topic).where(frm_topics: { hidden: false })
        end
      end

      def topic_not_pending_review
        joins(:topic).where(frm_topics: { state: 'approved' })
      end

      def moderate!(posts, scope: all)
        transaction do
          posts.each do |post_id, moderation|
            option = moderation.fetch('moderation_option', moderation[:moderation_option]).to_s
            next if option.blank?

            scope.find(post_id).moderate!(option)
          end
        end
      end
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

    # workflow 4.x updates its in-memory state but does not persist the custom
    # Rails 8 column. Keep the public events while making persistence explicit.
    def approve!
      update!(state: 'approved')
    end

    def spam!
      update!(state: 'spam')
    end

    def user_auto_subscribe?
      user.present?
    end

    def owner_or_admin?(other_user)
      user == other_user || other_user.forem_admin?(group)
    end

    def owner_or_moderator?(other_user)
      user == other_user || other_user.can_moderate_forem_forum?(forum) || other_user.forem_admin?(group)
    end

    # returns the number of his page in case of pagination on the topic
    def page
      ids = topic.posts.pluck(:id)
      position = ids.index(id)
      (position.to_f / TOPICS_PER_PAGE).ceil
    end

    protected

    def subscribe_replier
      topic.subscribe_user(user.id) if topic && user
    end

    def email_topic_subscribers
      topic.subscriptions.includes(:subscriber).find_each do |subscription|
        subscription.send_notification(id) if subscription.subscriber != user
      end
      update_attribute(:notified, true)
    end

    def set_topic_last_post_at
      topic.update_attribute(:last_post_at, created_at)
    end

    def apply_default_moderation_state
      self.state = 'approved' if state.blank? || state == 'pending_review'
    end

    def populate_token
      self.token = loop do
        random_token = SecureRandom.urlsafe_base64(16, false)
        break random_token unless Post.where(token: random_token).exists?
      end
    end

    def reply_to_belongs_to_topic
      errors.add(:reply_to, :invalid) if reply_to && topic && reply_to.topic_id != topic_id
    end
  end
end
