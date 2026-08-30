require 'rails_helper'
require 'requests_helper'

RSpec.describe SearchesController, seeds: true do
  let!(:user) { create(:user) }
  let!(:group) { create(:group, current_user_id: user.id) }

  describe 'GET index' do
    it 'requires authentication when not authenticated' do
      get searches_path, params: { term: 'test', format: :json }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns JSON when authenticated' do
      sign_in user
      get searches_path, params: { term: group.name, format: :json }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to be_an(Array)
    end

    it 'renders a labelled HTML search surface when authenticated' do
      sign_in user
      get searches_path, params: { term: group.name }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('search-results-title')
      expect(response.body).to include(group.name)
    end
  end
end
