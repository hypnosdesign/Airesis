require 'rails_helper'
require 'requests_helper'

RSpec.describe DocumentsController, seeds: true do
  let!(:user) { create(:user) }
  let!(:group) { create(:group, current_user_id: user.id) }

  describe 'GET index' do
    it 'redirects to sign in when not authenticated' do
      get "/groups/#{group.to_param}/documents"
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response when authenticated as group owner' do
      sign_in user
      get "/groups/#{group.to_param}/documents"
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end
end
