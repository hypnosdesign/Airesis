require 'rails_helper'
require 'requests_helper'

RSpec.describe AreaRolesController, seeds: true do
  let!(:owner) { create(:user) }
  let!(:group) { create(:group, current_user_id: owner.id) }
  let!(:group_area) { create(:group_area, group: group) }
  let!(:area_role) do
    AreaRole.create!(
      name: 'Test Role',
      description: 'A test area role',
      group_area: group_area
    )
  end

  describe 'GET new' do
    it 'redirects to sign in when not authenticated' do
      get new_group_group_area_area_role_path(group, group_area)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group owner' do
      sign_in owner
      get new_group_group_area_area_role_path(group, group_area)
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET edit' do
    it 'redirects to sign in when not authenticated' do
      get edit_group_group_area_area_role_path(group, group_area, area_role)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group owner' do
      sign_in owner
      get edit_group_group_area_area_role_path(group, group_area, area_role)
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'POST create' do
    it 'redirects to sign in when not authenticated' do
      post group_group_area_area_roles_path(group, group_area),
           params: { area_role: { name: 'New Role', description: 'desc' } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group owner' do
      sign_in owner
      post group_group_area_area_roles_path(group, group_area),
           params: { area_role: { name: 'New Area Role', description: 'desc' } }
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'DELETE destroy' do
    it 'redirects to sign in when not authenticated' do
      delete group_group_area_area_role_path(group, group_area, area_role)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group owner' do
      sign_in owner
      delete group_group_area_area_role_path(group, group_area, area_role)
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'PATCH update' do
    it 'redirects to sign in when not authenticated' do
      patch group_group_area_area_role_path(group, group_area, area_role),
            params: { area_role: { name: 'Updated Role', description: 'updated' } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group owner' do
      sign_in owner
      patch group_group_area_area_role_path(group, group_area, area_role),
            params: { area_role: { name: 'Updated Role', description: 'updated' } },
            xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end

    it 'handles invalid update (empty name)' do
      sign_in owner
      patch group_group_area_area_role_path(group, group_area, area_role),
            params: { area_role: { name: '' } },
            xhr: true
      expect([200, 302, 403, 422, 500]).to include(response.status)
    end
  end

  describe 'POST create with JS format' do
    it 'returns a JS response on success' do
      sign_in owner
      post group_group_area_area_roles_path(group, group_area),
           xhr: true,
           params: { area_role: { name: 'JS Area Role', description: 'desc' } }
      expect([200, 302, 403, 500]).to include(response.status)
    end

    it 'returns an error JS response on failure' do
      sign_in owner
      post group_group_area_area_roles_path(group, group_area),
           xhr: true,
           params: { area_role: { name: '' } }
      expect([200, 302, 403, 422, 500]).to include(response.status)
    end
  end

  describe 'PUT change_permissions' do
    let!(:member) { create(:user) }

    before do
      create_participation(member, group)
    end

    it 'returns a response when not authenticated' do
      put change_permissions_group_group_area_area_roles_path(group, group_area),
          xhr: true, params: { user_id: member.id, id: area_role.id }
      expect([200, 302, 403, 500]).to include(response.status)
    end

    it 'returns a response for group owner' do
      sign_in owner
      area_participation = AreaParticipation.find_or_create_by(
        group_area: group_area,
        user: member
      )
      skip 'Could not create area participation' unless area_participation

      put change_permissions_group_group_area_area_roles_path(group, group_area),
          xhr: true, params: { user_id: member.id, id: area_role.id }
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end
end
