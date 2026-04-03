AIRESIS_VERSION = '4.8.7'.freeze

if defined?(Sentry)
  Sentry.init do |config|
    config.dsn = ENV['SENTRY_DSN']
    config.release = AIRESIS_VERSION
    config.send_default_pii = false
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  end
end
