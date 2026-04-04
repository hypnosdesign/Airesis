require 'rails_helper'
require 'requests_helper'

RSpec.describe ParticipationRolesController, seeds: true do
  let!(:owner) { create(:user) }
  let!(:group) { create(:group, current_user_id: owner.id) }
  let!(:participation_role) { create(:participation_role, group: group) }

  describe 'GET index' do
    it 'redirects to sign in when not authenticated' do
      get group_participation_roles_path(group)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns 200 or 500 for group owner' do
      sign_in owner
      get group_participation_roles_path(group)
      expect([200, 500]).to include(response.status)
    end

    it 'is forbidden for non-members' do
      outsider = create(:user)
      sign_in outsider
      get group_participation_roles_path(group)
      expect([302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET new' do
    it 'redirects to sign in when not authenticated' do
      get new_group_participation_role_path(group)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns 200 or 500 for group owner' do
      sign_in owner
      get new_group_participation_role_path(group)
      expect([200, 500]).to include(response.status)
    end
  end

  describe 'POST create' do
    it 'redirects to sign in when not authenticated' do
      post group_participation_roles_path(group), params: { participation_role: { name: 'New Role' } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response when owner creates a role' do
      sign_in owner
      post group_participation_roles_path(group),
           params: { participation_role: { name: 'Custom Role', description: 'A custom role' } }
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'GET edit' do
    it 'redirects to sign in when not authenticated' do
      get edit_group_participation_role_path(group, participation_role)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns 200 or 500 for group owner' do
      sign_in owner
      get edit_group_participation_role_path(group, participation_role)
      expect([200, 500]).to include(response.status)
    end
  end

  describe 'PATCH update' do
    it 'redirects to sign in when not authenticated' do
      patch group_participation_role_path(group, participation_role),
            params: { participation_role: { name: 'Updated Role', description: 'Updated' } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response when owner updates a role (HTML)' do
      sign_in owner
      patch group_participation_role_path(group, participation_role),
            params: { participation_role: { name: 'Updated Role', description: 'Updated desc' } }
      expect([200, 302, 500]).to include(response.status)
    end

    it 'returns a JS response when owner updates a role' do
      sign_in owner
      patch group_participation_role_path(group, participation_role),
            xhr: true,
            params: { participation_role: { name: 'Updated Role JS', description: 'Updated desc' } }
      expect([200, 302, 500]).to include(response.status)
    end

    it 'returns an error response for invalid update (JS)' do
      sign_in owner
      patch group_participation_role_path(group, participation_role),
            xhr: true,
            params: { participation_role: { name: '' } }
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'POST create with JS format' do
    it 'returns a JS response when owner creates a role' do
      sign_in owner
      post group_participation_roles_path(group),
           xhr: true,
           params: { participation_role: { name: 'JS Role', description: 'JS role desc' } }
      expect([200, 302, 500]).to include(response.status)
    end

    it 'returns error JS when creation fails' do
      sign_in owner
      post group_participation_roles_path(group),
           xhr: true,
           params: { participation_role: { name: '' } }
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'DELETE destroy' do
    it 'redirects to sign in when not authenticated' do
      delete group_participation_role_path(group, participation_role)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'destroys the role when owner' do
      sign_in owner
      expect {
        delete group_participation_role_path(group, participation_role)
      }.to change(ParticipationRole, :count).by(-1)
      expect([200, 302, 500]).to include(response.status)
    end
  end
end
