require 'rails_helper'
require 'requests_helper'

RSpec.describe GroupAreasController, seeds: true do
  let!(:owner) { create(:user) }
  let!(:group) { create(:group, current_user_id: owner.id, enable_areas: true) }

  describe 'authentication and authorization' do
    it 'redirects guests to sign in' do
      get group_group_areas_path(group)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'renders the work-area index for the group owner' do
      sign_in owner
      get group_group_areas_path(group)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('main-content')
    end
  end

  describe 'POST create' do
    before { sign_in owner }

    it 'creates a complete work area and its default role' do
      expect do
        post group_group_areas_path(group), params: {
          group_area: { name: 'Accessibility team', description: 'Reviews inclusive participation.', default_role_name: 'Contributor' }
        }
      end.to change(group.group_areas, :count).by(1)

      area = group.group_areas.order(:created_at).last
      expect(response).to redirect_to(group_group_area_path(group, area))
      expect(area.default_area_role.name).to eq('Contributor')
    end

    it 'returns 422 and preserves validation errors' do
      expect do
        post group_group_areas_path(group), params: {
          group_area: { name: 'ab', description: 'Short name', default_role_name: 'Member' }
        }
      end.not_to change(GroupArea, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('ab')
    end
  end

  describe 'PATCH update' do
    let!(:group_area) { create(:group_area, group: group) }

    before { sign_in owner }

    it 'updates the area' do
      patch group_group_area_path(group, group_area), params: { group_area: { name: 'Updated accessibility team' } }
      expect(group_area.reload.name).to eq('Updated accessibility team')
      expect(response).to redirect_to(group_group_area_path(group, group_area))
    end

    it 'renders the edit page with 422 for invalid data' do
      patch group_group_area_path(group, group_area), params: { group_area: { name: 'ab' } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(group_area.reload.name).not_to eq('ab')
      expect(response.body).to include('ab')
    end
  end

  describe 'DELETE destroy' do
    let!(:group_area) { create(:group_area, group: group) }

    it 'destroys an empty area for the owner' do
      sign_in owner
      expect { delete group_group_area_path(group, group_area) }.to change(GroupArea, :count).by(-1)
      expect(response).to redirect_to(group_group_areas_path(group))
    end
  end
end
