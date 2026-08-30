require 'rails_helper'
require 'requests_helper'

RSpec.describe AreaRolesController, seeds: true do
  let!(:owner) { create(:user) }
  let!(:group) { create(:group, current_user_id: owner.id, enable_areas: true) }
  let!(:group_area) { create(:group_area, group: group) }
  let!(:area_role) { create_area_role('Coordinator') }

  def create_area_role(name)
    AreaRole.create!(name: name, description: "#{name} role", group_area: group_area)
  end

  describe 'authentication' do
    it 'redirects guests to sign in' do
      get new_group_group_area_area_role_path(group, group_area)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'HTML forms' do
    before { sign_in owner }

    it 'renders new and edit with a main landmark' do
      get new_group_group_area_area_role_path(group, group_area)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('main-content')

      get edit_group_group_area_area_role_path(group, group_area, area_role)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('main-content')
    end

    it 'creates a role' do
      expect do
        post group_group_area_area_roles_path(group, group_area), params: {
          area_role: { name: 'Reviewer', description: 'Reviews area proposals.' }
        }
      end.to change(group_area.area_roles, :count).by(1)
      expect(response).to redirect_to(group_group_area_path(group, group_area))
    end

    it 'returns 422 for an invalid create' do
      post group_group_area_area_roles_path(group, group_area), params: { area_role: { name: '', description: '' } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'returns 422 and preserves an invalid update' do
      patch group_group_area_area_role_path(group, group_area, area_role), params: { area_role: { name: '' } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(area_role.reload.name).to eq('Coordinator')
    end
  end

  describe 'PUT change_permissions' do
    let!(:member) { create(:user) }

    def create_area_participation
      create_participation(member, group)
      AreaParticipation.create!(group_area: group_area, area_role: group_area.default_area_role, user: member)
    end

    it 'lets a regular group owner assign a scoped role' do
      area_participation = create_area_participation
      sign_in owner
      put change_permissions_group_group_area_area_roles_path(group, group_area), params: {
        user_id: member.id, id: area_role.id
      }
      expect(response).to redirect_to(group_group_area_path(group, group_area))
      expect(area_participation.reload.area_role).to eq(area_role)
    end

    it 'cannot assign a role from another area' do
      area_participation = create_area_participation
      other_area = create(:group_area, group: group)
      other_role = AreaRole.create!(name: 'Other role', description: 'Other area role', group_area: other_area)
      sign_in owner

      expect do
        put change_permissions_group_group_area_area_roles_path(group, group_area), params: {
          user_id: member.id, id: other_role.id
        }
      end.not_to(change { area_participation.reload.area_role_id })
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE destroy' do
    it 'destroys a non-default role' do
      sign_in owner
      expect do
        delete group_group_area_area_role_path(group, group_area, area_role)
      end.to change(AreaRole, :count).by(-1)
    end

    it 'protects the default role' do
      sign_in owner
      expect do
        delete group_group_area_area_role_path(group, group_area, group_area.default_area_role)
      end.not_to change(AreaRole, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
