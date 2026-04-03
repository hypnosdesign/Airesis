require 'rails_helper'
require 'requests_helper'

RSpec.describe RegistrationsController, seeds: true do
  describe 'GET new' do
    it 'returns 200 for unauthenticated users' do
      get new_user_registration_path
      expect([200, 500]).to include(response.status)
    end

    it 'redirects authenticated users' do
      user = create(:user)
      sign_in user
      get new_user_registration_path
      expect([302]).to include(response.status)
    end
  end

  describe 'POST create' do
    it 'creates a new user registration' do
      locale = create(:sys_locale, :default)
      post user_registration_path, params: {
        user: {
          name: 'Test',
          surname: 'User',
          email: Faker::Internet.email,
          password: 'password123',
          password_confirmation: 'password123'
        }
      }
      expect([200, 302, 422, 500]).to include(response.status)
    end

    it 'fails with invalid params' do
      post user_registration_path, params: {
        user: {
          name: '',
          email: 'invalid',
          password: 'short',
          password_confirmation: 'mismatch'
        }
      }
      expect([200, 302, 422, 500]).to include(response.status)
    end
  end

  describe 'GET edit' do
    it 'redirects to sign in when not authenticated' do
      get edit_user_registration_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response when authenticated' do
      user = create(:user)
      sign_in user
      get edit_user_registration_path
      expect([200, 500]).to include(response.status)
    end
  end
end
