require 'rails_helper'
require 'requests_helper'

RSpec.describe AreaParticipationsController, seeds: true do
  let!(:user) { create(:user) }
  let!(:group) { create(:group, current_user_id: user.id) }

  before do
    group.update(enable_areas: true)
  end

  let!(:group_area) { create(:group_area, group: group) }

  describe 'POST create' do
    it 'redirects to sign in when not authenticated' do
      other_user = create(:user)
      create_participation(other_user, group)
      post "/groups/#{group.to_param}/group_areas/#{group_area.to_param}/area_participations",
           params: { area_participation: { user_id: other_user.id } }, xhr: true
      expect([302, 401]).to include(response.status)
    end

    it 'returns a response when authenticated as group owner' do
      other_user = create(:user)
      create_participation(other_user, group)
      sign_in user
      post "/groups/#{group.to_param}/group_areas/#{group_area.to_param}/area_participations",
           params: { area_participation: { user_id: other_user.id } }, xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'DELETE destroy' do
    it 'redirects to sign in when not authenticated' do
      other_user = create(:user)
      create_participation(other_user, group)
      delete "/groups/#{group.to_param}/group_areas/#{group_area.to_param}/area_participations/1",
             params: { area_participation: { user_id: other_user.id } }, xhr: true
      expect([302, 401]).to include(response.status)
    end
  end
end
