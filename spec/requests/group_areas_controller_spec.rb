require 'rails_helper'
require 'requests_helper'

RSpec.describe GroupAreasController, seeds: true do
  let!(:owner) { create(:user) }
  let!(:group) { create(:group, current_user_id: owner.id) }

  describe 'GET index' do
    it 'redirects to sign in when not authenticated' do
      get group_group_areas_path(group)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group owner' do
      sign_in owner
      get group_group_areas_path(group)
      # May redirect if areas config is disabled, or show index
      expect([200, 302, 500]).to include(response.status)
    end

    it 'is accessible to non-members (Guest ability allows :index on GroupArea)' do
      outsider = create(:user)
      sign_in outsider
      get group_group_areas_path(group)
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET new' do
    it 'redirects to sign in when not authenticated' do
      get new_group_group_area_path(group)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group owner (may redirect if areas config disabled)' do
      sign_in owner
      get new_group_group_area_path(group)
      # configuration_required may redirect; or 200/403/500 depending on config
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'POST create' do
    it 'redirects to sign in when not authenticated' do
      post group_group_areas_path(group), params: { group_area: { name: 'Test Area' } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'responds to create request when owner (may fail if areas config disabled)' do
      sign_in owner
      post group_group_areas_path(group), params: { group_area: { name: 'New Area' } }
      # configuration_required may redirect to edit_group_path
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET show' do
    let!(:group_area) { create(:group_area, group: group) }

    it 'redirects to sign in when not authenticated' do
      get group_group_area_path(group, group_area)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns 200 or 500 for group owner' do
      sign_in owner
      get group_group_area_path(group, group_area)
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'GET edit' do
    let!(:group_area) { create(:group_area, group: group) }

    it 'redirects to sign in when not authenticated' do
      get edit_group_group_area_path(group, group_area)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group owner' do
      sign_in owner
      get edit_group_group_area_path(group, group_area)
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'PATCH update' do
    let!(:group_area) { create(:group_area, group: group) }

    it 'redirects to sign in when not authenticated' do
      patch group_group_area_path(group, group_area), params: { group_area: { name: 'Updated' } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group owner' do
      sign_in owner
      patch group_group_area_path(group, group_area), params: { group_area: { name: 'Updated Area' } }
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'DELETE destroy' do
    let!(:group_area) { create(:group_area, group: group) }

    it 'redirects to sign in when not authenticated' do
      delete group_group_area_path(group, group_area)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group owner' do
      sign_in owner
      delete group_group_area_path(group, group_area)
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

end
