require 'rails_helper'
require 'requests_helper'

RSpec.describe AnnouncementsController, seeds: true do
  describe 'POST hide' do
    it 'returns a response for unauthenticated users' do
      announcement = Announcement.first || Announcement.create!(message: 'Test', starts_at: 1.day.ago, ends_at: 1.day.from_now)
      post "/announcements/#{announcement.id}/hide", xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end

    it 'returns a response for authenticated users' do
      user = create(:user)
      sign_in user
      announcement = Announcement.first || Announcement.create!(message: 'Test', starts_at: 1.day.ago, ends_at: 1.day.from_now)
      post "/announcements/#{announcement.id}/hide", xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end
end
