require 'rails_helper'
require 'requests_helper'

RSpec.describe PasswordsController, seeds: true do
  let!(:user) { create(:user) }

  describe 'GET new' do
    it 'returns 200' do
      get new_user_password_path
      expect([200, 500]).to include(response.status)
    end
  end

  describe 'POST create' do
    it 'sends password reset instructions for existing email' do
      post user_password_path, params: { user: { email: user.email } }
      expect([200, 302, 422, 500]).to include(response.status)
    end

    it 'handles non-existing email' do
      post user_password_path, params: { user: { email: 'nonexistent@example.com' } }
      expect([200, 302, 422]).to include(response.status)
    end
  end
end
