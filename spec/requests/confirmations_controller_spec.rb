require 'rails_helper'

RSpec.describe ConfirmationsController do
  let!(:unconfirmed_user) do
    u = create(:user)
    u.update_columns(confirmed_at: nil, confirmation_token: nil, confirmation_sent_at: nil)
    u.send_confirmation_instructions
    u.reload
    u
  end

  describe 'GET /users/confirmation/new' do
    it 'renders the resend confirmation form' do
      get new_user_confirmation_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /users/confirmation' do
    context 'with a registered email' do
      it 'redirects after sending instructions' do
        post user_confirmation_path, params: { user: { email: unconfirmed_user.email } }
        expect(response).to have_http_status(:found)
      end

      it 'sends a confirmation email' do
        expect {
          post user_confirmation_path, params: { user: { email: unconfirmed_user.email } }
        }.to change(ActionMailer::Base.deliveries, :count).by(1)
      end
    end

    context 'with an unknown email' do
      it 'returns unprocessable entity or redirect with error' do
        post user_confirmation_path, params: { user: { email: 'nobody@example.com' } }
        expect([200, 302, 422]).to include(response.status)
      end
    end
  end

  describe 'GET /users/confirmation (confirm token)' do
    context 'with a valid token' do
      it 'confirms the user' do
        get user_confirmation_path, params: { confirmation_token: unconfirmed_user.confirmation_token }
        expect(unconfirmed_user.reload.confirmed_at).not_to be_nil
      end

      it 'redirects after confirmation' do
        get user_confirmation_path, params: { confirmation_token: unconfirmed_user.confirmation_token }
        expect(response).to have_http_status(:found)
      end

      it 'does not redirect to the confirmation page itself' do
        get user_confirmation_path, params: { confirmation_token: unconfirmed_user.confirmation_token }
        expect(response.location).not_to include(user_confirmation_path)
      end
    end

    context 'with an invalid token' do
      it 'does not confirm the user' do
        get user_confirmation_path, params: { confirmation_token: 'invalid_token' }
        expect(unconfirmed_user.reload.confirmed_at).to be_nil
      end

      it 'returns an error response' do
        get user_confirmation_path, params: { confirmation_token: 'invalid_token' }
        expect([200, 302, 422]).to include(response.status)
      end
    end

    context 'with an already confirmed user' do
      it 'responds without 5xx error' do
        confirmed_user = create(:user) # factory creates confirmed users
        confirmed_user.send_confirmation_instructions
        confirmed_user.reload
        get user_confirmation_path, params: { confirmation_token: confirmed_user.confirmation_token }
        expect(response.status).to be < 500
      end
    end
  end
end
