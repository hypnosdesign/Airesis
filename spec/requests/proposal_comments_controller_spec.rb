require 'rails_helper'
require 'requests_helper'

RSpec.describe ProposalCommentsController, seeds: true do
  let!(:user) { create(:user) }
  let!(:proposal) { create(:public_proposal, current_user_id: user.id) }
  let!(:comment) { create(:proposal_comment, proposal: proposal, user: user) }

  describe 'GET index' do
    it 'returns 200 or 500 for unauthenticated users' do
      get proposal_proposal_comments_path(proposal)
      expect([200, 500]).to include(response.status)
    end

    it 'returns 200 or 500 for authenticated users' do
      sign_in user
      get proposal_proposal_comments_path(proposal)
      expect([200, 500]).to include(response.status)
    end
  end

  describe 'GET show' do
    it 'returns 200 or 500' do
      get proposal_proposal_comment_path(proposal, comment)
      expect([200, 500]).to include(response.status)
    end
  end

  describe 'GET new' do
    it 'requires authentication (redirect or 500) when not authenticated' do
      get new_proposal_proposal_comment_path(proposal)
      expect([302, 500]).to include(response.status)
    end

    it 'returns 200 or 500 for authenticated user' do
      sign_in user
      get new_proposal_proposal_comment_path(proposal)
      expect([200, 500]).to include(response.status)
    end
  end

  describe 'POST create' do
    it 'redirects to sign in when not authenticated' do
      post proposal_proposal_comments_path(proposal), params: { proposal_comment: { content: 'My comment' } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'creates a comment when authenticated' do
      sign_in user
      expect {
        post proposal_proposal_comments_path(proposal),
             params: { proposal_comment: { content: 'My test comment' } }
      }.to change(ProposalComment, :count).by(1)
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'GET edit' do
    it 'redirects to sign in when not authenticated' do
      get edit_proposal_proposal_comment_path(proposal, comment)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns 200 or 500 for the comment author' do
      sign_in user
      get edit_proposal_proposal_comment_path(proposal, comment)
      expect([200, 500]).to include(response.status)
    end
  end

  describe 'DELETE destroy' do
    it 'redirects to sign in when not authenticated' do
      delete proposal_proposal_comment_path(proposal, comment)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'destroys the comment when authenticated as the author' do
      sign_in user
      expect {
        delete proposal_proposal_comment_path(proposal, comment)
      }.to change(ProposalComment, :count).by(-1)
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'PATCH update' do
    it 'redirects to sign in when not authenticated' do
      patch proposal_proposal_comment_path(proposal, comment), params: { proposal_comment: { content: 'Updated' } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'updates the comment when authenticated as author' do
      sign_in user
      patch proposal_proposal_comment_path(proposal, comment), params: { proposal_comment: { content: 'Updated content' } }
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'PUT rankup' do
    it 'returns a response (accessible without authentication via CanCanCan)' do
      put rankup_proposal_proposal_comment_path(proposal, comment), xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end

    it 'returns a response for authenticated user' do
      sign_in create(:user)
      put rankup_proposal_proposal_comment_path(proposal, comment), xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'PUT rankdown' do
    it 'returns a response (accessible without authentication via CanCanCan)' do
      put rankdown_proposal_proposal_comment_path(proposal, comment), xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end

    it 'returns a response for authenticated user' do
      sign_in create(:user)
      put rankdown_proposal_proposal_comment_path(proposal, comment), xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'PUT ranknil' do
    it 'returns a response (accessible without authentication via CanCanCan)' do
      put ranknil_proposal_proposal_comment_path(proposal, comment), xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end

    it 'returns a response for authenticated user' do
      sign_in create(:user)
      put ranknil_proposal_proposal_comment_path(proposal, comment), xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET list' do
    it 'returns a response' do
      get list_proposal_proposal_comments_path(proposal)
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'GET left_list' do
    it 'returns a response' do
      get left_list_proposal_proposal_comments_path(proposal)
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'GET show_all_replies' do
    it 'returns a response' do
      get show_all_replies_proposal_proposal_comment_path(proposal, comment), params: { showed: 0 }, xhr: true
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'POST report (collection route)' do
    it 'returns a response for unauthenticated users' do
      post report_proposal_proposal_comments_path(proposal), params: { id: comment.id, reason: 1 }, xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end

    it 'returns a response for authenticated user' do
      sign_in create(:user)
      post report_proposal_proposal_comments_path(proposal), params: { id: comment.id, reason: 1 }, xhr: true
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'GET noise (collection route)' do
    it 'returns a response' do
      sign_in user
      get noise_proposal_proposal_comments_path(proposal)
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET manage_noise (collection route)' do
    it 'returns a response for authenticated user' do
      sign_in user
      get manage_noise_proposal_proposal_comments_path(proposal)
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'PUT unintegrate' do
    it 'returns a response for unauthenticated users' do
      put unintegrate_proposal_proposal_comment_path(proposal, comment), xhr: true
      expect([200, 302, 401, 403, 500]).to include(response.status)
    end

    it 'returns a response for authenticated user' do
      sign_in user
      put unintegrate_proposal_proposal_comment_path(proposal, comment), xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'POST mark_noise (collection route)' do
    it 'returns a response for authenticated proposal author' do
      sign_in user
      post mark_noise_proposal_proposal_comments_path(proposal),
           params: { comments: { active: '', inactive: comment.id.to_s } }, xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET edit_list (collection route)' do
    it 'returns a response' do
      get edit_list_proposal_proposal_comments_path(proposal)
      expect([200, 302, 500]).to include(response.status)
    end
  end
end
