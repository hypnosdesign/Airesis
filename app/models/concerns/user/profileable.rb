module User::Profileable
  extend ActiveSupport::Concern

  included do
    has_many :meeting_participations, dependent: :destroy
    has_many :user_borders, class_name: 'UserBorder'
    has_many :interest_borders, through: :user_borders, class_name: 'InterestBorder'
    belongs_to :image, class_name: 'Image', foreign_key: :image_id, optional: true
    belongs_to :locale, class_name: 'SysLocale', inverse_of: :users, foreign_key: 'sys_locale_id', optional: true
    belongs_to :original_locale, class_name: 'SysLocale', inverse_of: :original_users, foreign_key: 'original_sys_locale_id', optional: true
    
    has_many :tutorial_assignees, dependent: :destroy
    has_many :tutorials, through: :tutorial_assignees, class_name: 'Tutorial', source: :tutorial
    has_many :tutorial_progresses, dependent: :destroy
    has_many :todo_tutorial_assignees, -> { where('tutorial_assignees.completed = false') }, class_name: 'TutorialAssignee'
    has_many :todo_tutorials, through: :todo_tutorial_assignees, class_name: 'Tutorial', source: :tutorial

    has_many :events
  end

  def fullname
    "#{name} #{surname}"
  end

  def to_param
    "#{id}-#{fullname.downcase.gsub(/[^a-zA-Z0-9]+/, '-').gsub(/-{2,}/, '-').gsub(/^-|-$/, '')}"
  end

  def to_s
    fullname
  end

  def user_image_url(size = 80, _params = {})
    user = respond_to?(:user) ? self.user : self

    if user.avatar.attached?
      Rails.application.routes.url_helpers.rails_blob_path(user.avatar, only_path: true)
    elsif user.email.present?
      require 'digest/md5'
      hash = Digest::MD5.hexdigest(user.email.downcase)
      "https://www.gravatar.com/avatar/#{hash}?s=#{size}"
    else
      ''
    end
  end

  def geocode
    @search = Geocoder.search(last_sign_in_ip)
    unless @search.empty?
      @latlon = [@search[0].latitude, @search[0].longitude]
      @zone = begin
                Timezone::Zone.new latlon: @latlon
              rescue StandardError
                nil
              end
      update(time_zone: @zone.active_support_time_zone) if @zone
    end
  end

  def assign_tutorials
    Tutorial.all.find_each do |tutorial|
      assign_tutorial(self, tutorial)
    end
    GeocodeUser.set(wait: 5.seconds).perform_later(id)
  end

  def update_borders
    return unless interest_borders_tokens

    interest_borders_tokens.split(',').each do |border|
      ftype = border[0, 1]
      fid = border[2..]
      found = InterestBorder.table_element(border)
      next unless found

      derived_row = found
      while derived_row
        self.derived_interest_borders_tokens |= [InterestBorder.to_key(derived_row)]
        derived_row = derived_row.parent
      end

      interest_b = InterestBorder.find_or_create_by(territory_type: InterestBorder::I_TYPE_MAP[ftype],
                                                    territory_id: fid)
      user_borders.build(interest_border_id: interest_b.id)
    end
  end
end
