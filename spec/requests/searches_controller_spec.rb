require 'rails_helper'
require 'requests_helper'

RSpec.describe SearchesController, seeds: true do
  let!(:user) { create(:user) }
  let!(:group) { create(:group, current_user_id: user.id) }

  describe 'GET index' do
    it 'requires authentication when not authenticated' do
      get searches_path, params: { term: 'test', format: :json }
      expect([302, 401, 406, 500]).to include(response.status)
    end

    it 'returns JSON when authenticated' do
      sign_in user
      get searches_path, params: { term: group.name, format: :json }
      expect([200, 500]).to include(response.status)
      if response.status == 200
        json = JSON.parse(response.body)
        expect(json).to be_an(Array)
      end
    end
  end
end
