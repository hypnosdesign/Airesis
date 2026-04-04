require 'rails_helper'

RSpec.describe RegistrationsController do
  let(:valid_params) do
    {
      user: {
        name: 'Mario',
        surname: 'Rossi',
        email: 'mario.rossi@example.com',
        password: 'password123',
        password_confirmation: 'password123',
        accept_conditions: '1',
        accept_privacy: '1'
      }
    }
  end

  describe 'GET /users/sign_up' do
    context 'when unauthenticated' do
      it 'renders the registration form' do
        get new_user_registration_path
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when already authenticated' do
      it 'redirects away from the sign-up page' do
        sign_in create(:user)
        get new_user_registration_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'POST /users' do
    context 'with valid params' do
      it 'creates the user' do
        expect { post user_registration_path, params: valid_params }.to change(User, :count).by(1)
      end

      it 'creates an unconfirmed user (confirmable)' do
        post user_registration_path, params: valid_params
        expect(User.find_by(email: 'mario.rossi@example.com').confirmed_at).to be_nil
      end

      it 'assigns a confirmation token' do
        post user_registration_path, params: valid_params
        expect(User.find_by(email: 'mario.rossi@example.com').confirmation_token).to be_present
      end

      it 'redirects to sign-in after registration' do
        post user_registration_path, params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'with invalid params' do
      it 'does not create user when name is blank' do
        params = valid_params.deep_merge(user: { name: '' })
        expect { post user_registration_path, params: params }.not_to change(User, :count)
        expect(response).to have_http_status(:ok) # Devise re-renders form with 200
      end

      it 'does not create user when email is invalid' do
        params = valid_params.deep_merge(user: { email: 'not-an-email' })
        expect { post user_registration_path, params: params }.not_to change(User, :count)
        expect(response).to have_http_status(:ok)
      end

      it 'does not create user when passwords do not match' do
        params = valid_params.deep_merge(user: { password_confirmation: 'different' })
        expect { post user_registration_path, params: params }.not_to change(User, :count)
        expect(response).to have_http_status(:ok)
      end

      it 'does not create user when EULA is not accepted' do
        params = valid_params.deep_merge(user: { accept_conditions: '0' })
        expect { post user_registration_path, params: params }.not_to change(User, :count)
        expect(response).to have_http_status(:ok)
      end

      it 'does not create user when email is already taken' do
        create(:user, email: 'mario.rossi@example.com')
        expect { post user_registration_path, params: valid_params }.not_to change(User, :count)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET /users/edit' do
    it 'redirects to sign-in when unauthenticated' do
      get edit_user_registration_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'renders the edit form when authenticated' do
      sign_in create(:user)
      get edit_user_registration_path
      expect(response).to have_http_status(:ok)
    end
  end
end
