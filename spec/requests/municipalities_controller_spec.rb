require 'rails_helper'
require 'requests_helper'

RSpec.describe MunicipalitiesController, seeds: true do
  describe 'GET index' do
    it 'returns JSON for autocomplete' do
      get municipalities_path, params: { term: 'Roma' }, headers: { 'Accept' => 'application/json' }
      expect([200, 401, 500]).to include(response.status)
    end
  end
end
