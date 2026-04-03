module User::Socializable
  extend ActiveSupport::Concern

  included do
    has_one :blog, inverse_of: :user, dependent: :destroy
    has_many :blog_comments, inverse_of: :user, dependent: :destroy
    has_many :blog_posts, inverse_of: :user, dependent: :destroy
    has_many :event_comments, dependent: :destroy, inverse_of: :user
    has_many :likes, class_name: 'EventCommentLike', dependent: :destroy, inverse_of: :user

    has_many :followers_user_follow, class_name: 'UserFollow', foreign_key: :followed_id
    has_many :followers, through: :followers_user_follow, class_name: 'User', source: :followed

    has_many :followed_user_follow, class_name: 'UserFollow', foreign_key: :follower_id
    has_many :followed, through: :followed_user_follow, class_name: 'User', source: :follower
  end

  def is_my_blog_post?(blog_post_id)
    blog_posts.exists?(id: blog_post_id)
  end

  def is_my_blog?(blog_id)
    blog && blog.id == blog_id
  end
end
