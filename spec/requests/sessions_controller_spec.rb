require 'rails_helper'

RSpec.describe SessionsController do
  let!(:user) { create(:user) }

  describe 'GET /users/sign_in' do
    it 'renders the login form when unauthenticated' do
      get new_user_session_path
      expect(response).to have_http_status(:ok)
    end

    it 'redirects to root when already authenticated' do
      sign_in user
      get new_user_session_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe 'POST /users/sign_in' do
    context 'with valid credentials' do
      it 'redirects after successful login' do
        post user_session_path, params: { user: { email: user.email, password: 'topolino' } }
        expect(response).to have_http_status(:found)
      end

      it 'does not redirect to the sign-in page' do
        post user_session_path, params: { user: { email: user.email, password: 'topolino' } }
        expect(response.location).not_to include(new_user_session_path)
      end
    end

    context 'with invalid credentials' do
      it 'redirects back with 401 or re-renders' do
        post user_session_path, params: { user: { email: user.email, password: 'wrong' } }
        expect([200, 401, 302]).to include(response.status)
      end

      it 'does not authenticate the user' do
        post user_session_path, params: { user: { email: user.email, password: 'wrong' } }
        expect(request.env['warden'].user).to be_nil
      end
    end

    context 'with unconfirmed user' do
      let!(:unconfirmed_user) do
        u = create(:user)
        u.update_columns(confirmed_at: nil)
        u
      end

      it 'does not allow login and redirects with error' do
        post user_session_path, params: { user: { email: unconfirmed_user.email, password: 'topolino' } }
        expect([200, 302]).to include(response.status)
        expect(request.env['warden'].user).to be_nil
      end
    end

    context 'with blocked user' do
      before { user.update_column(:blocked, true) }

      it 'does not authenticate and redirects' do
        post user_session_path, params: { user: { email: user.email, password: 'topolino' } }
        expect(request.env['warden'].user).to be_nil
      end
    end
  end

  describe 'DELETE /users/sign_out' do
    it 'signs out and redirects when authenticated' do
      sign_in user
      delete destroy_user_session_path
      expect(response).to have_http_status(:found)
    end

    it 'redirects to root or sign-in after logout' do
      sign_in user
      delete destroy_user_session_path
      expect(response.location).to match(%r{/(users/sign_in)?$})
    end

    it 'does not allow access to protected resources after logout' do
      sign_in user
      delete destroy_user_session_path
      get edit_user_registration_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
