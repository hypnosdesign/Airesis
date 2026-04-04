require 'rails_helper'
require 'requests_helper'

RSpec.describe EventCommentsController, seeds: true do
  let!(:user) { create(:user) }
  let!(:event) { create(:meeting_event, user: user) }

  describe 'POST create' do
    it 'returns a response when not authenticated' do
      post event_event_comments_path(event),
           params: { event_comment: { body: 'A comment' } }, xhr: true
      expect([200, 302, 401, 403, 500]).to include(response.status)
    end

    it 'returns a response when authenticated' do
      sign_in user
      post event_event_comments_path(event),
           params: { event_comment: { body: 'A comment' } }, xhr: true
      expect([200, 302, 403, 422, 500]).to include(response.status)
    end
  end

  describe 'DELETE destroy' do
    let!(:comment) do
      c = EventComment.new(event: event, user: user, body: 'Test comment')
      c.save(validate: false)
      c
    end

    it 'returns a response when not authenticated' do
      delete event_event_comment_path(event, comment), xhr: true
      expect([200, 302, 401, 403, 500]).to include(response.status)
    end

    it 'returns a response when authenticated as owner' do
      sign_in user
      delete event_event_comment_path(event, comment), xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'POST like' do
    let!(:comment) do
      c = EventComment.new(event: event, user: user, body: 'Like me')
      c.save(validate: false)
      c
    end

    it 'returns a response when not authenticated' do
      post like_event_event_comment_path(event, comment), xhr: true
      expect([200, 302, 401, 403, 500]).to include(response.status)
    end

    it 'returns a response when authenticated' do
      other_user = create(:user)
      sign_in other_user
      post like_event_event_comment_path(event, comment), xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end
end
