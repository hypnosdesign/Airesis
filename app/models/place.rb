class Place < ApplicationRecord
  belongs_to :municipality
  has_one :meeting

  validates :municipality_id, :address, presence: true
end
