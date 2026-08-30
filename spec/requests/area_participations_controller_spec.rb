require 'rails_helper'
require 'requests_helper'

RSpec.describe AreaParticipationsController, seeds: true do
  let!(:owner) { create(:user) }
  let!(:group) { create(:group, current_user_id: owner.id, enable_areas: true) }
  let!(:group_area) { create(:group_area, group: group) }
  let!(:member) { create(:user) }

  before { create_participation(member, group) }

  describe 'POST create' do
    it 'redirects guests to sign in' do
      post group_group_area_area_participations_path(group, group_area), params: { area_participation: { user_id: member.id } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'adds a group member with the area default role' do
      sign_in owner
      expect do
        post group_group_area_area_participations_path(group, group_area), params: { area_participation: { user_id: member.id } }
      end.to change(group_area.area_participations, :count).by(1)

      participation = group_area.area_participations.find_by!(user: member)
      expect(participation.area_role).to eq(group_area.default_area_role)
      expect(response).to redirect_to(group_group_area_path(group, group_area))
    end

    it 'does not add an outsider to the area' do
      outsider = create(:user)
      sign_in owner
      expect do
        post group_group_area_area_participations_path(group, group_area), params: { area_participation: { user_id: outsider.id } }
      end.not_to change(AreaParticipation, :count)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE destroy' do
    let!(:area_participation) do
      AreaParticipation.create!(group_area: group_area, area_role: group_area.default_area_role, user: member)
    end

    it 'removes only the nested area participation' do
      sign_in owner
      expect do
        delete group_group_area_area_participation_path(group, group_area, area_participation), params: { area_participation: { user_id: member.id } }
      end.to change(AreaParticipation, :count).by(-1)
      expect(response).to redirect_to(group_group_area_path(group, group_area))
    end
  end
end
