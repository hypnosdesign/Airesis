class UpdateSitemap < ApplicationJob
  queue_as :low_priority

  def perform(*_args)
    Rake::Task['sitemap:refresh'].invoke
  end
end
