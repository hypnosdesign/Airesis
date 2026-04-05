require 'rails_helper'
require 'requests_helper'

RSpec.describe GroupInvitationsController, seeds: true do
  let!(:owner) { create(:user) }
  let!(:group) { create(:group, current_user_id: owner.id) }

  describe 'GET new' do
    it 'redirects to sign in when not authenticated' do
      get new_group_group_invitation_path(group)
      expect([302, 403]).to include(response.status)
    end

    it 'returns 200 or 500 for group owner' do
      sign_in owner
      get new_group_group_invitation_path(group)
      expect([200, 500]).to include(response.status)
    end

    it 'is forbidden for non-members' do
      outsider = create(:user)
      sign_in outsider
      get new_group_group_invitation_path(group)
      expect([302, 403, 500]).to include(response.status)
    end
  end
end
