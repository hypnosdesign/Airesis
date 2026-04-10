# Be sure to restart your server when you modify this file.

Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  policy.font_src    :self, :https, :data,
                     'https://fonts.googleapis.com', 'https://fonts.gstatic.com',
                     'https://cdnjs.cloudflare.com'
  policy.img_src     :self, :https, :data, :blob
  policy.object_src  :none
  # unsafe-inline necessario per Stimulus/Turbo inline event handlers e Tailwind JIT
  policy.script_src  :self, :unsafe_inline, 'https://cdn.jsdelivr.net', 'https://cdn.renuo.ch'
  policy.style_src   :self, :unsafe_inline,
                     'https://fonts.googleapis.com', 'https://cdnjs.cloudflare.com'
  policy.connect_src :self, :https,
                     'https://nominatim.openstreetmap.org', # Leaflet geocoding
                     'https://*.sentry.io'                 # Sentry reporting
  policy.frame_src   :none
  policy.media_src   :self
end
