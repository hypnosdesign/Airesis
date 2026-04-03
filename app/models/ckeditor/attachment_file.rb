module Ckeditor
  class AttachmentFile < Ckeditor::Asset
    has_one_attached :data

    validates :data, presence: true,
                     size: { less_than: UPLOAD_LIMIT_ATTACHMENTS.bytes }


    def url_thumb
      @url_thumb ||= Ckeditor::Utils.filethumb(filename)
    end
  end
end
