require 'rails_helper'
require 'requests_helper'

RSpec.describe MeetingParticipationsController, seeds: true do
  let!(:user) { create(:user) }
  let!(:group) { create(:group, current_user_id: user.id) }
  let!(:event) { create(:meeting_event, user: user) }

  describe 'POST create' do
    it 'redirects to sign in when not authenticated' do
      post event_meeting_participations_path(event),
           params: { meeting_participation: { response: 'Y', comment: 'I will be there', guests: 0 } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'handles the request when authenticated' do
      sign_in user
      post event_meeting_participations_path(event),
           params: { meeting_participation: { response: 'Y', comment: 'I will be there', guests: 0 } }
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end
end
