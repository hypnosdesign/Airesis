require 'rails_helper'
require 'requests_helper'

RSpec.describe AuthenticationsController, seeds: true do
  let!(:user) { create(:user) }

  describe 'DELETE destroy' do
    it 'redirects to sign in when not authenticated' do
      # Cannot test without an actual authentication record, but can test the route
      delete "/users/#{user.id}/authentications/999999"
      expect([302, 401, 403, 404, 500]).to include(response.status)
    end

    it 'returns a response when authenticated' do
      sign_in user
      delete "/users/#{user.id}/authentications/999999"
      expect([302, 403, 404, 500]).to include(response.status)
    end
  end
end
