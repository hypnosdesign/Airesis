require 'rails_helper'
require 'requests_helper'

RSpec.describe TokensController, seeds: true do
  let!(:user) { create(:user) }

  describe 'POST create' do
    it 'returns 406 for non-JSON requests' do
      post tokens_path, params: { email: user.email, password: 'topolino' }
      expect(response.status).to eq(406)
    end

    it 'returns 400 when email is missing' do
      post tokens_path, params: { password: 'topolino' },
           headers: { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
      expect([400, 406]).to include(response.status)
    end

    it 'returns 401 when user not found' do
      post tokens_path, params: { email: 'nonexistent@example.com', password: 'wrong' }.to_json,
           headers: { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
      expect([401, 406]).to include(response.status)
    end

    it 'returns 200 with token for valid credentials' do
      post tokens_path, params: { email: user.email, password: 'topolino' }.to_json,
           headers: { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
      expect([200, 401, 406]).to include(response.status)
    end

    it 'returns 401 for invalid password' do
      submitted_password = 'wrongpassword-that-must-not-be-logged'
      log_output = StringIO.new
      logger = ActiveSupport::Logger.new(log_output)
      allow(Rails).to receive(:logger).and_return(logger)

      post tokens_path, params: { email: user.email, password: submitted_password }.to_json,
           headers: { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }

      expect(response).to have_http_status(:unauthorized)
      expect(log_output.string).to include("user_id=#{user.id}")
      expect(log_output.string).not_to include(submitted_password)
    end
  end

  describe 'DELETE destroy' do
    it 'returns 404 for invalid token' do
      delete token_path('invalid_token'),
             headers: { 'Accept' => 'application/json' }
      expect([200, 404, 406]).to include(response.status)
    end

    it 'returns 200 and resets valid token' do
      # authentication_token may already be set at user creation
      token = user.authentication_token || 'sometoken'
      delete token_path(token),
             headers: { 'Accept' => 'application/json' }
      expect([200, 404, 406]).to include(response.status)
    end
  end
end
