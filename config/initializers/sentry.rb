APP_VERSION = '5.0.0'.freeze
AIRESIS_VERSION = APP_VERSION # backward compat alias

if defined?(Sentry)
  Sentry.init do |config|
    config.dsn = ENV['SENTRY_DSN']
    config.release = AIRESIS_VERSION
    config.send_default_pii = false
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  end
end
