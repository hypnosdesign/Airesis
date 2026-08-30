require 'rails_helper'
require 'requests_helper'

RSpec.describe ProposalCategoriesController, seeds: true do
  describe 'GET index' do
    it 'responds to the index request' do
      get proposal_categories_path, params: { format: :json }
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('application/json')
      expect(JSON.parse(response.body)).to all(include('id', 'description'))
    end

    it 'returns 200 with JSON accept header' do
      get proposal_categories_path,
          headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('application/json')
    end
  end
end
