module User::Authenticatable
  extend ActiveSupport::Concern

  included do
    has_many :authentications, class_name: 'Authentication', dependent: :destroy
    
    # devise :database_authenticatable, :registerable, :confirmable, :omniauthable,
    #        :blockable, :recoverable, :rememberable, :trackable, :validatable, :traceable
  end

  def from_identity_provider?
    authentications.any?
  end

  def has_provider?(provider_name)
    authentications.exists?(provider: provider_name)
  end

  def build_authentication_provider(access_token)
    authentications.build(
      provider: access_token['provider'],
      uid: access_token['uid'],
      token: access_token.dig('credentials', 'token')
    )
  end

  def facebook
    @fb_user ||= begin
                   Koala::Facebook::API.new(authentications.find_by(provider: Authentication::FACEBOOK).try(:token))
                 rescue StandardError
                   nil
                 end
  end

  def oauth_join(oauth_data)
    oauth_data_parser = OauthDataParser.new(oauth_data)
    provider = oauth_data_parser.provider
    raw_info = oauth_data_parser.raw_info
    user_info = oauth_data_parser.user_info

    self.class.transaction do
      build_authentication_provider(oauth_data)
      self.email = user_info[:email] unless email
      set_social_network_pages(provider, raw_info)
      save!
    end
  end

  def set_social_network_pages(provider, raw_info)
    self.google_page_url = raw_info['profile'] if provider == Authentication::GOOGLE
    self.facebook_page_url = raw_info['link'] if provider == Authentication::FACEBOOK
  end

  def twitter_page_url
    auth = authentications.find_by(provider: Authentication::TWITTER)
    "https://twitter.com/intent/user?user_id=#{auth.uid}" if auth
  end

  def send_reset_password_instructions
    if blocked
      errors.add(:base, :not_found)
      return false
    end
    super
  end

  def has_oauth_provider_without_email
    has_provider?(Authentication::TWITTER)
  end

  class_methods do
    def find_or_create_for_oauth_provider(oauth_data)
      oauth_data_parser = OauthDataParser.new(oauth_data)
      provider = oauth_data_parser.provider
      uid = oauth_data_parser.uid
      user_info = oauth_data_parser.user_info

      auth = Authentication.find_by(provider: provider, uid: uid)
      if auth
        [auth.user, false, false]
      else
        user = user_info[:email] && User.find_by(email: user_info[:email])
        user ? [user, true, true] : [create_account_for_oauth(oauth_data), true, false]
      end
    end

    def create_account_for_oauth(oauth_data)
      oauth_data_parser = OauthDataParser.new(oauth_data)
      provider = oauth_data_parser.provider
      raw_info = oauth_data_parser.raw_info
      user_info = oauth_data_parser.user_info

      return nil if user_info[:name].blank?

      user = User.new(
        name: user_info[:name],
        surname: user_info[:surname],
        password: Devise.friendly_token[0, 20],
        sex: user_info[:sex],
        email: user_info[:email]
      )

      user.tap do |u|
        u.avatar_url = user_info[:avatar_url]
        u.google_page_url = raw_info['profile'] if provider == Authentication::GOOGLE
        u.facebook_page_url = raw_info['link'] if provider == Authentication::FACEBOOK

        transaction do
          u.build_authentication_provider(oauth_data)
          u.sign_in_count = 0
          u.confirm
          u.user_type_id = :authenticated
          u.save!
        end
      end
    end
  end
end
