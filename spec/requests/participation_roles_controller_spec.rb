require 'rails_helper'
require 'requests_helper'

RSpec.describe ParticipationRolesController, seeds: true do
  let!(:owner) { create(:user) }
  let!(:group) { create(:group, current_user_id: owner.id) }
  let!(:participation_role) { create(:participation_role, group: group) }

  describe 'authentication and authorization' do
    it 'redirects guests to sign in' do
      get group_participation_roles_path(group)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'renders the role index for the owner' do
      sign_in owner
      get group_participation_roles_path(group)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('main-content')
    end
  end

  describe 'POST create' do
    before { sign_in owner }

    it 'creates a role' do
      expect {
        post group_participation_roles_path(group), params: {
          participation_role: { name: 'Facilitator', description: 'Facilitates decisions.' }
        }
      }.to change(group.participation_roles, :count).by(1)
      expect(response).to redirect_to(group_participation_roles_path(group))
    end

    it 'returns 422 for invalid data' do
      post group_participation_roles_path(group), params: { participation_role: { name: '', description: '' } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'returns 422 and the same form for an invalid Turbo submission' do
      post group_participation_roles_path(group),
           params: { participation_role: { name: '', description: '' } },
           headers: { 'ACCEPT' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(response.body).to include('participation_role_modal')
    end
  end

  describe 'PATCH update' do
    before { sign_in owner }

    it 'persists permissions explicitly' do
      patch group_participation_role_path(group, participation_role), params: {
        participation_role: { name: participation_role.name, description: participation_role.description, write_to_wall: '1' }
      }
      expect(response).to redirect_to(group_participation_roles_path(group))
      expect(participation_role.reload.write_to_wall).to be(true)
    end

    it 'returns 422 and keeps invalid data in the form' do
      patch group_participation_role_path(group, participation_role), params: {
        participation_role: { name: '', description: participation_role.description }
      }
      expect(response).to have_http_status(:unprocessable_content)
      expect(participation_role.reload.name).not_to eq('')
    end
  end

  describe 'DELETE destroy' do
    it 'destroys a custom role with a Turbo-safe redirect' do
      sign_in owner
      expect {
        delete group_participation_role_path(group, participation_role)
      }.to change(ParticipationRole, :count).by(-1)
      expect(response).to have_http_status(:see_other)
    end

    it 'protects the group default role' do
      sign_in owner
      expect {
        delete group_participation_role_path(group, group.default_participation_role)
      }.not_to change(ParticipationRole, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end

  it 'does not publish the removed show and change-default routes' do
    actions = Rails.application.routes.routes.filter_map do |route|
      route.defaults[:action] if route.defaults[:controller] == 'participation_roles'
    end

    expect(actions).not_to include('show', 'change_default_role')
  end
end
