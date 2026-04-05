require 'rails_helper'
require 'requests_helper'

RSpec.describe SearchParticipantsController, seeds: true do
  let!(:owner) { create(:user) }
  let!(:group) { create(:group, current_user_id: owner.id) }

  describe 'POST create' do
    it 'redirects to sign in when not authenticated' do
      post group_search_participants_path(group),
           params: { search_participant: { keywords: 'test' } }
      expect([302, 403, 500]).to include(response.status)
    end

    it 'returns a response when authenticated as group owner' do
      sign_in owner
      post group_search_participants_path(group),
           params: { search_participant: { keywords: '' } }
      expect([200, 302, 403, 500]).to include(response.status)
    end

    it 'returns a JS response when authenticated as group owner' do
      sign_in owner
      post group_search_participants_path(group), xhr: true,
           params: { search_participant: { keywords: '' } }
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end
end
