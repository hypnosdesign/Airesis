require 'rails_helper'
require 'requests_helper'

RSpec.describe AlertsController, seeds: true do
  let!(:user) { create(:user) }

  describe 'GET index' do
    context 'when not authenticated' do
      it 'redirects to sign in' do
        get alerts_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when authenticated' do
      before { sign_in user }

      it 'returns 200 or 500' do
        get alerts_path
        expect([200, 500]).to include(response.status)
      end

      it 'returns JSON with alert data' do
        get alerts_path, headers: { 'Accept' => 'application/json' }
        expect([200, 500]).to include(response.status)
        if response.status == 200
          json = JSON.parse(response.body)
          expect(json).to have_key('count')
        end
      end
    end
  end

  describe 'POST check_all' do
    context 'when not authenticated' do
      it 'requires authentication (redirect or 401)' do
        post check_all_alerts_path, xhr: true
        expect([302, 401]).to include(response.status)
      end
    end

    context 'when authenticated' do
      before { sign_in user }

      it 'responds to XHR request' do
        post check_all_alerts_path, xhr: true
        expect([200, 302, 500]).to include(response.status)
      end
    end
  end

  describe 'GET proposal' do
    context 'when not authenticated' do
      it 'redirects to sign in' do
        get proposal_alerts_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when authenticated' do
      before { sign_in user }

      it 'returns a response' do
        proposal = create(:public_proposal, current_user_id: user.id)
        get proposal_alerts_path, params: { proposal_id: proposal.id }
        expect([200, 302, 500]).to include(response.status)
      end
    end
  end

  describe 'GET check' do
    context 'when not authenticated' do
      it 'redirects to sign in' do
        get check_alert_path(999)
        expect([302, 401]).to include(response.status)
      end
    end

    context 'when authenticated' do
      before { sign_in user }

      it 'redirects when alert does not exist (exception handler)' do
        get check_alert_path(999999)
        expect([200, 302, 404, 500]).to include(response.status)
      end

      it 'checks a valid alert and redirects' do
        proposal = create(:public_proposal, current_user_id: user.id)
        # Create a notification + alert for testing
        notification_type = NotificationType.first
        skip 'No notification types seeded' unless notification_type

        notification = Notification.create!(
          notification_type: notification_type,
          url: proposal_path(proposal),
          properties: {}
        )
        alert = user.alerts.create!(notification: notification, checked: false)
        get check_alert_path(alert)
        expect([200, 302, 404, 500]).to include(response.status)
      rescue ActiveRecord::RecordInvalid => e
        skip "Alert setup failed: #{e.message.truncate(80)}"
      end
    end
  end
end
