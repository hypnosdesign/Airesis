require 'rails_helper'
require 'requests_helper'

RSpec.describe MunicipalitiesController, seeds: true do
  let!(:user) { create(:user) }

  describe 'GET index' do
    it 'returns JSON for autocomplete' do
      sign_in user
      get municipalities_path, params: { term: 'Roma' }, headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to be_an(Array)
    end

    it 'requires authentication' do
      get municipalities_path, params: { term: 'Roma' }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
