# Gestisce le funzionalità social dell'utente: blog personale, commenti agli eventi, follower.
#
# Ogni utente ha un blog personale (uno solo, `has_one :blog`).
# Il sistema di follower è bidirezionale tramite la join table `user_follows`:
# - `followers` — utenti che seguono questo utente (foreign_key: `followed_id`)
# - `followed`  — utenti che questo utente segue (foreign_key: `follower_id`)
# Nota: i nomi possono sembrare scambiati, ma l'associazione è corretta:
# `followers_user_follow` (chi mi segue) usa `followed_id = self.id`.
module User::Socializable
  extend ActiveSupport::Concern

  included do
    has_one :blog, inverse_of: :user, dependent: :destroy
    has_many :blog_comments, inverse_of: :user, dependent: :destroy
    has_many :blog_posts, inverse_of: :user, dependent: :destroy
    has_many :event_comments, dependent: :destroy, inverse_of: :user
    has_many :likes, class_name: 'EventCommentLike', dependent: :destroy, inverse_of: :user

    # Utenti che seguono ME: UserFollow.followed_id = self.id
    has_many :followers_user_follow, class_name: 'UserFollow', foreign_key: :followed_id
    has_many :followers, through: :followers_user_follow, class_name: 'User', source: :followed

    # Utenti che IO seguo: UserFollow.follower_id = self.id
    has_many :followed_user_follow, class_name: 'UserFollow', foreign_key: :follower_id
    has_many :followed, through: :followed_user_follow, class_name: 'User', source: :follower
  end

  # @param blog_post_id [Integer]
  # @return [Boolean] true se il post appartiene a questo utente
  def is_my_blog_post?(blog_post_id)
    blog_posts.exists?(id: blog_post_id)
  end

  # @param blog_id [Integer]
  # @return [Boolean] true se il blog appartiene a questo utente
  def is_my_blog?(blog_id)
    blog && blog.id == blog_id
  end
end
