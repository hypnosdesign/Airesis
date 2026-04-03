class SysPaymentNotification < ApplicationRecord
  belongs_to :payable, polymorphic: true
  serialize :params, coder: YAML

  # after_create
end
