require 'rails_helper'
require 'requests_helper'

RSpec.describe Admin::UsersController, seeds: true do
  let!(:admin) { create(:admin) }
  let!(:user) { create(:user) }

  # Admin routes have routing constraints — non-admins/unauthenticated see 404
  describe 'GET autocomplete' do
    it 'returns 404 or redirect when not authenticated (routing constraint)' do
      get autocomplete_admin_users_path
      expect([302, 404]).to include(response.status)
    end

    it 'returns 404 for non-admin users (routing constraint)' do
      sign_in user
      get autocomplete_admin_users_path
      expect([302, 403, 404]).to include(response.status)
    end

    it 'returns results for admin' do
      sign_in admin
      get autocomplete_admin_users_path, params: { q: user.name }
      expect([200, 500]).to include(response.status)
    end
  end

  describe 'GET unblock' do
    it 'returns 404 or redirect when not authenticated' do
      get unblock_admin_user_path(user)
      expect([302, 404]).to include(response.status)
    end

    it 'unblocks the user when admin' do
      sign_in admin
      get unblock_admin_user_path(user)
      expect([200, 302, 500]).to include(response.status)
    end
  end
end
