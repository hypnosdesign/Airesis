require 'rails_helper'

RSpec.describe 'OmniAuth security configuration' do
  it 'enables TLS certificate verification for Facebook' do
    strategy_options = Devise.omniauth_configs.fetch(:facebook).strategy

    expect(strategy_options[:client_options][:ssl][:verify]).to be(true)
  end

  it 'loads Facebook credentials only from the environment' do
    devise_initializer = Rails.root.join('config/initializers/devise.rb').read

    expect(devise_initializer).to include("ENV['FACEBOOK_APP_ID']")
    expect(devise_initializer).to include("ENV['FACEBOOK_APP_SECRET']")
  end

  it 'does not contain legacy hard-coded Facebook credentials' do
    legacy_initializer = Rails.root.join('config/initializers/omniauth.rb').read

    expect(legacy_initializer).not_to match(/provider\s+:facebook/)
    expect(legacy_initializer).not_to match(/\b\d{10,}\b/)
    expect(legacy_initializer).not_to match(/\b[0-9a-f]{32}\b/i)
  end
end
