require 'rails_helper'
require 'requests_helper'

RSpec.describe EventCommentsController, seeds: true do
  let!(:owner) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:event) { create(:meeting_event, user: owner, private: false) }
  let(:turbo_headers) { { 'ACCEPT' => Mime[:turbo_stream].to_s } }

  describe 'POST create' do
    it 'requires authentication' do
      post event_event_comments_path(event), params: { event_comment: { body: 'A comment' } }

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'creates a valid root comment' do
      sign_in other_user

      expect do
        post event_event_comments_path(event),
             params: { event_comment: { body: 'Step-free access is available.' } },
             headers: turbo_headers
      end.to change(EventComment, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(EventComment.last.comment).to be_nil
      expect(EventComment.last.user).to eq(other_user)
    end

    it 'returns 422 with the invalid comment preserved' do
      sign_in other_user

      expect do
        post event_event_comments_path(event),
             params: { event_comment: { body: '' } },
             headers: turbo_headers
      end.not_to change(EventComment, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('eventNewComment')
      expect(response.body).to include('must be filled')
    end

    it 'rejects a comment longer than the database limit without raising an error' do
      sign_in other_user
      oversized_body = 'x' * (EventComment::MAX_BODY_LENGTH + 1)

      expect do
        post event_event_comments_path(event),
             params: { event_comment: { body: oversized_body } },
             headers: turbo_headers
      end.not_to change(EventComment, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(oversized_body)
    end
  end

  describe 'DELETE destroy' do
    let!(:comment) { create(:event_comment, event: event, user: owner) }

    it 'allows the author to delete their comment' do
      sign_in owner

      expect do
        delete event_event_comment_path(event, comment), headers: turbo_headers
      end.to change(EventComment, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end

    it 'rejects another user' do
      sign_in other_user

      expect do
        delete event_event_comment_path(event, comment), headers: turbo_headers
      end.not_to change(EventComment, :count)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST like' do
    let!(:comment) { create(:event_comment, event: event, user: owner) }

    it 'toggles the current user like and refreshes the comment' do
      sign_in other_user

      expect do
        post like_event_event_comment_path(event, comment), headers: turbo_headers
      end.to change(EventCommentLike, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("event_comment_#{comment.id}")
    end

    it 'does not accept a comment from another event' do
      other_event = create(:meeting_event, user: owner, private: false)
      other_comment = create(:event_comment, event: other_event, user: owner)
      sign_in other_user

      post like_event_event_comment_path(event, other_comment), headers: turbo_headers

      expect(response).to have_http_status(:not_found)
      expect(other_comment.reload.likes).to be_empty
    end
  end
end
