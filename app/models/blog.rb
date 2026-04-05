class Blog < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: %i[slugged history]
  include PgSearch::Model

  pg_search_scope :search, lambda { |query, any_word = false|
    { query: query,
      against: :title,
      order_within_rank: 'updated_at desc',
      using: { tsearch: { any_word: any_word } } }
  }

  belongs_to :user
  has_many :blog_posts, dependent: :destroy
  has_many :comments, through: :blog_posts, source: :blog_comments

  validates :title, length: { in: 1..100 }

  def last_post
    blog_posts.order(created_at: :desc).first
  end

  def solr_country_id
    territory = user.original_locale.territory
    territory.id if territory.is_a?(Country)
  end

  def solr_continent_id
    territory = user.original_locale.territory
    territory.is_a?(Country) ? territory.continent.id : territory.id
  end

  def self.look(params)
    search_term = params[:search]
    tag = params[:tag]
    interest_border = params[:interest_border]

    if tag
      Blog.joins(blog_posts: :tags).
        where(['tags.text = ?', tag]).distinct.
        order(updated_at: :desc)
    else
      blogs = if search_term.blank?
                Blog.order(updated_at: :desc)
              else
                search(search_term, !params[:and])
              end
      blogs = blogs.joins(:user).merge(User.by_interest_borders(interest_border)) if interest_border
      blogs
    end
  end

  def should_generate_new_friendly_id?
    title_changed?
  end
end
