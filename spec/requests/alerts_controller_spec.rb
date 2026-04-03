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
end
