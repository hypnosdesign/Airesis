require 'rails_helper'
require 'requests_helper'

RSpec.describe AnnouncementsController, seeds: true do
  describe 'POST hide' do
    it 'returns a response for unauthenticated users' do
      announcement = Announcement.first || Announcement.create!(message: 'Test', starts_at: 1.day.ago, ends_at: 1.day.from_now)
      post hide_announcement_path(announcement), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
    end

    it 'returns a response for authenticated users' do
      user = create(:user)
      sign_in user
      announcement = Announcement.first || Announcement.create!(message: 'Test', starts_at: 1.day.ago, ends_at: 1.day.from_now)
      post hide_announcement_path(announcement), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      expect(response).to have_http_status(:ok)
    end

    it 'is idempotent when the same announcement is dismissed twice' do
      announcement = Announcement.create!(message: 'One', starts_at: 1.day.ago, ends_at: 1.day.from_now)
      post hide_announcement_path(announcement), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      expect(response).to have_http_status(:ok)
      post hide_announcement_path(announcement), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      expect(response).to have_http_status(:ok)
      expect(response.cookies['hidden_announcement_ids']).to be_present
    end
  end
end
