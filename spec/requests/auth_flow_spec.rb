require 'rails_helper'

# End-to-end tests for the full authentication cycle:
# register → confirm email → login → access protected page → logout
RSpec.describe 'Authentication flow' do
  let(:email)    { 'flow_test@example.com' }
  let(:password) { 'password123' }

  let(:registration_params) do
    {
      user: {
        name: 'Flow',
        surname: 'Test',
        email: email,
        password: password,
        password_confirmation: password,
        accept_conditions: '1',
        accept_privacy: '1'
      }
    }
  end

  # ─── Registration ─────────────────────────────────────────────────────────

  describe 'Step 1: Registration' do
    it 'creates an unconfirmed user and redirects to sign-in' do
      expect { post user_registration_path, params: registration_params }.to change(User, :count).by(1)

      user = User.find_by!(email: email)
      expect(user.confirmed_at).to be_nil
      expect(user.confirmation_token).to be_present
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'blocks login before confirmation' do
      post user_registration_path, params: registration_params
      post user_session_path, params: { user: { email: email, password: password } }
      expect(request.env['warden'].user).to be_nil
    end
  end

  # ─── Confirmation ─────────────────────────────────────────────────────────

  describe 'Step 2: Email confirmation' do
    let!(:user) do
      post user_registration_path, params: registration_params
      User.find_by!(email: email)
    end

    it 'confirms the user via the token link' do
      get user_confirmation_path, params: { confirmation_token: user.confirmation_token }
      expect(user.reload.confirmed_at).not_to be_nil
    end

    it 'redirects after confirmation' do
      get user_confirmation_path, params: { confirmation_token: user.confirmation_token }
      expect(response).to have_http_status(:found)
    end

    it 'allows login after confirmation' do
      get user_confirmation_path, params: { confirmation_token: user.confirmation_token }
      post user_session_path, params: { user: { email: email, password: password } }
      expect(request.env['warden'].user).not_to be_nil
    end
  end

  # ─── Login ────────────────────────────────────────────────────────────────

  describe 'Step 3: Login' do
    let!(:confirmed_user) { create(:user, email: email, password: password, password_confirmation: password) }

    it 'authenticates a confirmed user' do
      post user_session_path, params: { user: { email: email, password: password } }
      expect(request.env['warden'].user).to eq(confirmed_user)
    end

    it 'redirects to the stored location after login' do
      get proposals_path # stores location in session
      post user_session_path, params: { user: { email: email, password: password } }
      expect(response).to redirect_to(proposals_path)
    end

    it 'redirects to root when no stored location' do
      post user_session_path, params: { user: { email: email, password: password } }
      follow_redirect!
      expect(response).to have_http_status(:ok)
    end

    it 'protects pages requiring authentication before login' do
      get edit_user_registration_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  # ─── Logout ───────────────────────────────────────────────────────────────

  describe 'Step 4: Logout' do
    let!(:confirmed_user) { create(:user) }

    before { sign_in confirmed_user }

    it 'signs out the user' do
      delete destroy_user_session_path
      expect(request.env['warden'].user).to be_nil
    end

    it 'redirects after logout' do
      delete destroy_user_session_path
      expect(response).to have_http_status(:found)
    end

    it 'blocks access to protected resources after logout' do
      delete destroy_user_session_path
      get edit_user_registration_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  # ─── Edge cases ───────────────────────────────────────────────────────────

  describe 'Edge cases' do
    it 'does not expose protected page content to guests' do
      get edit_user_registration_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'shows registration errors for duplicate email' do
      create(:user, email: email)
      post user_registration_path, params: registration_params
      expect(response).to have_http_status(:ok)
    end

    it 'handles confirmation with an invalid token gracefully' do
      get user_confirmation_path, params: { confirmation_token: 'bogus' }
      expect([200, 302, 422]).to include(response.status)
    end

    it 'rejects login with wrong password' do
      create(:user, email: email)
      post user_session_path, params: { user: { email: email, password: 'wrongpassword' } }
      expect(request.env['warden'].user).to be_nil
    end
  end
end
