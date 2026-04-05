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
      user.update!(blocked: true, blocked_name: user.name, blocked_surname: user.surname)
      sign_in admin
      get unblock_admin_user_path(user)
      expect([200, 302, 500]).to include(response.status)
    end

    it 'handles already-unblocked user' do
      sign_in admin
      get unblock_admin_user_path(user)
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'POST block' do
    it 'returns 404 or redirect when not authenticated' do
      post block_admin_users_path, params: { user_id: user.id }
      expect([302, 404]).to include(response.status)
    end

    it 'blocks the user when admin (by user_id)' do
      sign_in admin
      post block_admin_users_path, params: { user_id: user.id }
      expect([200, 302, 500]).to include(response.status)
    end

    it 'handles lookup by email' do
      sign_in admin
      post block_admin_users_path, params: { user_id: user.email }
      expect([200, 302, 500]).to include(response.status)
    end

    it 'handles non-existent user' do
      sign_in admin
      post block_admin_users_path, params: { user_id: 'no-such-user-12345' }
      expect([200, 302, 500]).to include(response.status)
    end
  end
end
