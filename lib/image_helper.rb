module ImageHelper
  def group_image_tag(size = 80, url = false)
    group = respond_to?(:group) ? self.group : self

    src = if group.image.attached?
            Rails.application.routes.url_helpers.rails_blob_path(group.image, only_path: true)
          else
            ActionController::Base.helpers.asset_path('gruppo-anonimo.png')
          end
    src = "#{ENV['SITE']}#{src}" if url
    style = size ? "width:#{size}px;height:#{size}px;overflow:hidden;" : ''
    ActionController::Base.helpers.tag.img(src: src, style: style, alt: group.name)
  end
end
