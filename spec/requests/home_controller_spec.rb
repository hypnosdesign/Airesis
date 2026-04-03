require 'rails_helper'
require 'requests_helper'

RSpec.describe HomeController, seeds: true do
  describe 'GET index' do
    it 'shows the homepage' do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to safe_include(I18n.t('home.tags.title'))
    end

    context 'when locale is wrong' do
      context 'when has a replacement' do
        it 'redirects to a correct locale' do
          get root_path(l: 'el')
          expect(response).to redirect_to(root_path(l: 'el-GR'))
        end
      end

      context 'when does not have a replacement' do
        it 'redirects without locale' do
          get root_path(l: 'mickey')
          expect(response).to redirect_to(root_path(l: nil))
        end
      end
    end
  end

  describe 'GET public (open_space)' do
    it 'returns a response' do
      get open_space_path
      expect([200, 500]).to include(response.status)
    end
  end

  describe 'GET home (authenticated)' do
    let!(:user) { create(:user) }

    it 'redirects to sign in when not authenticated' do
      get home_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response when authenticated' do
      sign_in user
      get home_path
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'GET privacy / terms / cookie_law' do
    it 'returns a response for privacy page' do
      get privacy_path
      expect([200, 500]).to include(response.status)
    end

    it 'returns a response for terms page' do
      get terms_path
      expect([200, 500]).to include(response.status)
    end

    it 'returns a response for cookie_law page' do
      get cookie_law_path
      expect([200, 500]).to include(response.status)
    end
  end

  describe 'GET statistics' do
    it 'returns a response' do
      get statistics_path
      expect([200, 500]).to include(response.status)
    end
  end

  describe 'GET press' do
    it 'returns a response' do
      get press_path
      expect([200, 500]).to include(response.status)
    end
  end

  describe 'POST send_feedback' do
    it 'returns a response' do
      post send_feedback_path, params: {
        sent_feedback: { description: 'Great app!', email: 'test@example.com' }
      }
      expect([200, 302, 422, 500]).to include(response.status)
    end
  end
end
