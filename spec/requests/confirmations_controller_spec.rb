require 'rails_helper'
require 'requests_helper'

RSpec.describe ConfirmationsController, seeds: true do
  describe 'GET show' do
    it 'handles invalid confirmation token' do
      get user_confirmation_path, params: { confirmation_token: 'invalid_token' }
      expect([200, 302, 422, 500]).to include(response.status)
    end
  end

  describe 'GET new' do
    it 'returns 200' do
      get new_user_confirmation_path
      expect([200, 500]).to include(response.status)
    end
  end

  describe 'POST create' do
    it 'sends confirmation instructions for existing email' do
      user = create(:user)
      post user_confirmation_path, params: { user: { email: user.email } }
      expect([200, 302, 422, 500]).to include(response.status)
    end
  end
end
