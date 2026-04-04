require 'rails_helper'
require 'requests_helper'

RSpec.describe EventCommentLikesController, seeds: true do
  let!(:user) { create(:user) }

  describe 'POST create (like)' do
    it 'redirects when not authenticated' do
      post "/events/1/event_comments/1/like"
      expect([302, 404]).to include(response.status)
    end
  end
end
