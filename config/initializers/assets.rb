# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
Rails.application.config.assets.paths << Rails.root.join('app/assets/builds')
Rails.application.config.assets.paths << Rails.root.join('node_modules')

# Precompile additional assets.
Rails.application.config.assets.precompile += %w[application.js rails_admin.js sentry_init.js
                                                 paypal-button.min.js tailwind.css
                                                 pdf/proposal.css newsletters.css]
