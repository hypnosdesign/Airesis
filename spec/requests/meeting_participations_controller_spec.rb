require 'rails_helper'
require 'requests_helper'

RSpec.describe MeetingParticipationsController, seeds: true do
  let!(:user) { create(:user) }
  let!(:event) { create(:meeting_event, user: create(:user), private: false) }
  let(:turbo_headers) { { 'ACCEPT' => Mime[:turbo_stream].to_s } }
  let(:valid_params) do
    { meeting_participation: { response: 'Y', comment: 'I can welcome participants.', guests: 0 } }
  end

  describe 'POST create' do
    it 'requires authentication' do
      post event_meeting_participations_path(event), params: valid_params

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'saves attendance for the current user' do
      sign_in user

      expect do
        post event_meeting_participations_path(event), params: valid_params
      end.to change(MeetingParticipation, :count).by(1)

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(event_path(event))
      expect(MeetingParticipation.last.user).to eq(user)
    end

    it 'returns 422 Turbo with invalid values preserved' do
      sign_in user
      long_comment = 'x' * 256

      expect do
        post event_meeting_participations_path(event),
             params: { meeting_participation: { response: 'Y', guests: 0, comment: long_comment } },
             headers: turbo_headers
      end.not_to change(MeetingParticipation, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('participation_panel_container')
      expect(response.body).to include(long_comment)
    end

    it 'rejects unsupported responses and negative guest counts' do
      sign_in user

      expect do
        post event_meeting_participations_path(event),
             params: { meeting_participation: { response: 'MAYBE', guests: -1, comment: '' } },
             headers: turbo_headers
      end.not_to change(MeetingParticipation, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('participation_panel_container')
    end
  end

  describe 'PATCH update' do
    let!(:participation) do
      create(:meeting_participation, meeting: event.meeting, user: user, response: 'Y', guests: 0)
    end

    it 'lets the attendee correct their response' do
      sign_in user

      patch event_meeting_participation_path(event, participation),
            params: { meeting_participation: { response: 'N', guests: 0, comment: 'Plans changed.' } }

      expect(response).to have_http_status(:see_other)
      expect(participation.reload.response).to eq('N')
      expect(participation.comment).to eq('Plans changed.')
    end

    it 'does not update another user attendance' do
      intruder = create(:user)
      sign_in intruder

      patch event_meeting_participation_path(event, participation),
            params: { meeting_participation: { response: 'N', guests: 0 } },
            headers: turbo_headers

      expect(response).to have_http_status(:forbidden)
      expect(participation.reload.response).to eq('Y')
    end
  end
end
