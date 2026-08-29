require 'rails_helper'

RSpec.describe 'OmniAuth security configuration' do
  it 'enables TLS certificate verification for Facebook' do
    strategy_options = Devise.omniauth_configs.fetch(:facebook).strategy

    expect(strategy_options[:client_options][:ssl][:verify]).to be(true)
  end
end
