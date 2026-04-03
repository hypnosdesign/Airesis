class SentFeedback < ApplicationRecord
  has_one_attached :image

  validates :image, size: { less_than: 2.megabytes },
                    content_type: ['image/png']


  validates :message, length: { maximum: 10.kilobytes }
end
