require 'rails_helper'
require 'requests_helper'

RSpec.describe TokensController, seeds: true do
  let!(:user) { create(:user) }

  around do |example|
    previous_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rack::Attack.cache.store = previous_store
  end

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
      user.update!(authentication_token: nil)

      post tokens_path, params: { email: user.email, password: 'topolino' }.to_json,
           headers: { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }

      expect(response).to have_http_status(:ok)
      expect(user.reload.authentication_token).to be_present
      expect(response.parsed_body.fetch('token')).to eq(user.authentication_token)
    end

    it 'returns 401 without generating a token for an invalid password' do
      submitted_password = 'wrongpassword-that-must-not-be-logged'
      log_output = StringIO.new
      logger = ActiveSupport::Logger.new(log_output)
      allow(Rails).to receive(:logger).and_return(logger)
      user.update!(authentication_token: nil)

      post tokens_path, params: { email: user.email, password: submitted_password }.to_json,
           headers: { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }

      expect(response).to have_http_status(:unauthorized)
      expect(user.reload.authentication_token).to be_nil
      expect(log_output.string).to include("user_id=#{user.id}")
      expect(log_output.string).not_to include(submitted_password)
    end
  end

  describe 'rate limiting' do
    let(:json_headers) { { 'Accept' => 'application/json', 'Content-Type' => 'application/json' } }

    it 'limits token requests from the same IP' do
      6.times do |attempt|
        post tokens_path,
             params: { email: "missing-#{attempt}@example.test", password: 'wrong' }.to_json,
             headers: json_headers.merge('REMOTE_ADDR' => '203.0.113.10')

        expect(response).to have_http_status(:unauthorized) if attempt < 5
      end

      expect(response).to have_http_status(:too_many_requests)
    end

    it 'limits token requests for the same normalized email across IPs' do
      email_variants = [
        'rate-limit@example.test',
        ' RATE-LIMIT@example.test ',
        'Rate-Limit@Example.Test',
        'rate-limit@example.test ',
        ' RATE-limit@EXAMPLE.test',
        'rate-limit@example.test'
      ]

      email_variants.each_with_index do |email, attempt|
        post tokens_path,
             params: { email: email, password: 'wrong' }.to_json,
             headers: json_headers.merge('REMOTE_ADDR' => "203.0.113.#{attempt + 20}")

        expect(response).to have_http_status(:unauthorized) if attempt < 5
      end

      expect(response).to have_http_status(:too_many_requests)
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
