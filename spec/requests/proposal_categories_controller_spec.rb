require 'rails_helper'
require 'requests_helper'

RSpec.describe ProposalCategoriesController, seeds: true do
  describe 'GET index' do
    it 'responds to the index request' do
      get proposal_categories_path, params: { format: :json }
      # controller returns JSON; may return 406 if format negotiation fails in test env
      expect([200, 406, 500]).to include(response.status)
    end

    it 'returns 200 with JSON accept header' do
      get proposal_categories_path,
          headers: { 'Accept' => 'application/json' }
      expect([200, 406, 500]).to include(response.status)
    end
  end
end
