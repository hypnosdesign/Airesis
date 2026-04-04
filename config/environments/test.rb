Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = false
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}"
  }

  config.active_storage.service = :test
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = false
  config.action_dispatch.show_exceptions = true
  config.action_controller.allow_forgery_protection = false
  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :test
  config.action_mailer.logger = nil
  config.active_support.report_deprecations = true
  # Disable parameter filtering in SQL logs to avoid Rails 7.1 ParameterFilter recursion bug
  # with complex bind parameters (e.g. from Globalize uniqueness validators)
  config.filter_parameters = []
  config.i18n.raise_on_missing_translations = true

  config.default_url_options = config.action_mailer.default_url_options

  config.i18n.available_locales += %w[en]
end

Rails.application.default_url_options = Rails.application.config.action_mailer.default_url_options
