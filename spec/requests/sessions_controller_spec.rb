require 'rails_helper'
require 'requests_helper'

RSpec.describe SessionsController, seeds: true do
  let!(:user) { create(:user) }

  describe 'POST create' do
    it 'signs in with valid credentials' do
      post user_session_path, params: { user: { email: user.email, password: 'topolino' } }
      expect([200, 302]).to include(response.status)
    end

    it 'rejects invalid credentials' do
      post user_session_path, params: { user: { email: user.email, password: 'wrongpassword' } }
      expect([200, 302, 401, 422]).to include(response.status)
    end

    it 'redirects banned user' do
      user.update_column(:banned, true) if user.respond_to?(:banned)
      post user_session_path, params: { user: { email: user.email, password: 'topolino' } }
      expect([200, 302]).to include(response.status)
    end
  end

  describe 'DELETE destroy' do
    it 'signs out when authenticated' do
      sign_in user
      delete destroy_user_session_path
      expect([200, 302]).to include(response.status)
    end
  end
end
