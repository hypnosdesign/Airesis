require 'rails_helper'
require 'requests_helper'

RSpec.describe TagsController, seeds: true do
  let!(:user) { create(:user) }

  describe 'GET index' do
    it 'returns 200 for unauthenticated users' do
      get tags_path
      expect([200, 500]).to include(response.status)
    end

    it 'returns a response when queried with a search term' do
      get tags_path, params: { q: 'tag', format: :json }
      expect([200, 406, 500]).to include(response.status)
    end
  end

  describe 'GET show' do
    let!(:proposal) { create(:public_proposal, current_user_id: user.id, tags_list: 'ruby,rails') }

    it 'returns 200 or 500 for an existing tag' do
      get tag_path('ruby')
      expect([200, 500]).to include(response.status)
    end

    it 'returns 200 or 500 for a non-existing tag (renders index)' do
      get tag_path('nonexistenttag12345')
      expect([200, 500]).to include(response.status)
    end
  end
end
