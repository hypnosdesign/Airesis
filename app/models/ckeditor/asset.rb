module Ckeditor
  class Asset < ApplicationRecord
    include Ckeditor::Orm::ActiveRecord::AssetBase
    include Ckeditor::Backend::ActiveStorage
  end
end
