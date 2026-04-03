# TODO: to remove
class Image < ApplicationRecord
  attr_accessor :random_id

  has_one_attached :image

  validates :image, presence: true,
                    size: { less_than: 2.megabytes },
                    content_type: ['image/jpeg', 'image/png']

end
