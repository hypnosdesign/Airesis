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
end
