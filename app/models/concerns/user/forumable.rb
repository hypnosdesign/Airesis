module User::Forumable
  extend ActiveSupport::Concern

  included do
    has_many :viewed, class_name: 'Frm::View'
    has_many :viewed_topics, class_name: 'Frm::Topic', through: :viewed, source: :viewable, source_type: 'Frm::Topic'
    has_many :unread_topics, -> { where 'frm_views.updated_at < frm_topics.last_post_at' }, class_name: 'Frm::Topic', through: :viewed, source: :viewable, source_type: 'Frm::Topic'
    has_many :memberships, class_name: 'Frm::Membership', inverse_of: :member, foreign_key: :member_id
    has_many :frm_mods, through: :memberships, class_name: 'Frm::Mod', source: :mod
  end

  def can_read_forem_category?(category)
    category.visible_outside || (category.group.participants.include? self)
  end

  def can_read_forem_forum?(forum)
    forum.visible_outside || (forum.group.participants.include? self)
  end

  def can_create_forem_topics?(forum)
    forum.group.participants.include? self
  end

  def can_reply_to_forem_topic?(topic)
    topic.forum.group.participants.include? self
  end

  def can_edit_forem_posts?(forum)
    forum.group.participants.include? self
  end

  def can_read_forem_topic?(topic)
    !topic.hidden? || forem_admin?(topic.forum.group) || (topic.user == self)
  end

  def can_moderate_forem_forum?(forum)
    forum.moderator?(self)
  end

  def forem_admin?(group)
    can? :update, group
  end
end
