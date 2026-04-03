module Ckeditor
  class Picture < Ckeditor::Asset
    has_one_attached :data

    validates :data, presence: true,
                     content_type: /\Aimage/,
                     size: { less_than: UPLOAD_LIMIT_IMAGES.bytes }


    def url_content
      url(:content)
    end
  end
end
