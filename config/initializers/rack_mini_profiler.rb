# Disabilitato: il JS di mini-profiler sovrascrive window.fetch
# e causa crash con Turbo 8 (map.get is not a function).
# Riabilitare quando mini-profiler rilascia un fix compatibile con Turbo 8.
# if Rails.env.development?
#   require 'rack-mini-profiler'
#   Rack::MiniProfiler.config.position = 'left'
#   Rack::MiniProfilerRails.initialize!(Rails.application)
# end
