require 'rails_helper'
require 'requests_helper'

RSpec.describe TagsController, seeds: true do
  let!(:user) { create(:user) }

  describe 'GET index' do
    it 'returns 200 for unauthenticated users' do
      get tags_path
      expect(response).to have_http_status(:ok)
    end

    it 'returns a response when queried with a search term' do
      get tags_path, params: { q: 'tag', format: :json }
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('application/json')
    end
  end

  describe 'GET show' do
    let!(:proposal) { create(:public_proposal, current_user_id: user.id, tags_list: 'ruby,rails') }

    it 'returns 200 for an existing tag' do
      get tag_path('ruby')
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('ruby')
    end

    it 'returns 200 for a non-existing tag and renders the directory' do
      get tag_path('nonexistenttag12345')
      expect(response).to have_http_status(:ok)
    end
  end
end
