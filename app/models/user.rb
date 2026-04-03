require 'digest/sha1'

class User < ApplicationRecord
  acts_as_token_authenticatable

  devise :database_authenticatable, :registerable, :confirmable, :omniauthable,
         :blockable, :recoverable, :rememberable, :trackable, :validatable, :traceable

  include User::Authenticatable
  include User::Proposable
  include User::Groupable
  include User::Socializable
  include User::Forumable
  include User::Notificationable
  include User::Profileable
  include TutorialAssigneesHelper

  attr_accessor :image_url, :accept_conditions, :accept_privacy, :interest_borders_tokens

  validates :name, presence: true, length: { maximum: 50 }, format: { with: AuthenticationModule.name_regex, allow_nil: true }
  validates :surname, length: { maximum: 50 }, format: { with: AuthenticationModule.name_regex, allow_nil: true }
  validates :password, confirmation: true
  validates :accept_conditions, acceptance: { message: -> { I18n.t('activerecord.errors.messages.TOS') } }
  validates :accept_privacy, acceptance: { message: -> { I18n.t('activerecord.errors.messages.privacy') } }

  enum user_type_id: { administrator: 1, moderator: 2, authenticated: 3 }, _prefix: true

  # Attachments
  has_one_attached :avatar

  validates :avatar, content_type: ['image/jpeg', 'image/png', 'image/gif'],
                     size: { less_than: UPLOAD_LIMIT_IMAGES.bytes }



  # Scopes
  scope :all_except, ->(user) { where.not(id: user) }
  scope :blocked, -> { where(blocked: true) }
  scope :unblocked, -> { where(blocked: false) }
  scope :confirmed, -> { where 'confirmed_at is not null' }
  scope :unconfirmed, -> { where 'confirmed_at is null' }
  scope :count_active, -> { unblocked.count.to_f * (ENV['ACTIVE_USERS_PERCENTAGE'].to_f / 100.0) }
  scope :autocomplete, ->(term) { where('lower(users.name) LIKE :term or lower(users.surname) LIKE :term', term: "%#{term.to_s.downcase}%").order('users.surname desc, users.name desc').limit(10) }
  scope :by_interest_borders, ->(ib) { where('users.derived_interest_borders_tokens @> ARRAY[?]::varchar[]', ib) }

  # Callbacks
  before_create :init
  after_create :assign_tutorials
  before_update :before_update_populate

  def avatar_url=(url)
    return if url.blank?

    avatar.attach(io: URI.open(url), filename: File.basename(URI.parse(url).path))
  rescue StandardError
    # ignored
  end

  def email_required?
    super && !has_oauth_provider_without_email
  end

  def init
    self.rank ||= 0
    self.receive_messages = true
    self.receive_newsletter = true
    update_borders
    init_notifications
  end

  def admin?
    user_type_id_administrator?
  end

  def moderator?
    admin? || user_type_id_moderator?
  end

  def is_mine?(object)
    return false unless object
    if object.respond_to?('user_id')
      object.user_id == id
    elsif object.respond_to?('users')
      object.users.exists?(id: id)
    else
      false
    end
  end

  def encoded_id
    Base64.encode64(id.to_s)
  end

  def self.decode_id(id)
    Base64.decode64(id)
  end

  def image_url
    avatar.attached? ? Rails.application.routes.url_helpers.rails_blob_path(avatar, only_path: true) : nil
  end

  delegate :can?, :cannot?, to: :ability

  def ability
    @ability ||= Ability.new(self)
  end

  private

  def reconfirmation_required?
    self.class.reconfirmable && @reconfirmation_required
  end

  def before_update_populate
    user_borders.destroy_all
    update_borders
  end
end
