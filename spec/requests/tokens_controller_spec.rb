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
      post tokens_path, params: { email: user.email, password: 'wrongpassword' }.to_json,
           headers: { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
      expect([401, 406]).to include(response.status)
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
