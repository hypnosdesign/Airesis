require 'rails_helper'
require 'requests_helper'

RSpec.describe ProposalCommentsController, seeds: true do
  let!(:user) { create(:user) }
  let!(:proposal) { create(:public_proposal, current_user_id: user.id) }
  let!(:comment) { create(:proposal_comment, proposal: proposal, user: user) }

  it 'renders the contribution index for guests and authenticated users' do
    get proposal_proposal_comments_path(proposal)
    expect(response).to have_http_status(:ok)

    sign_in user
    get proposal_proposal_comments_path(proposal)
    expect(response).to have_http_status(:ok)
  end

  it 'does not expose the removed standalone show and new routes' do
    expect do
      Rails.application.routes.recognize_path("/proposals/#{proposal.id}/proposal_comments/#{comment.id}", method: :get)
    end.to raise_error(ActionController::RoutingError)
    expect do
      Rails.application.routes.recognize_path("/proposals/#{proposal.id}/proposal_comments/new", method: :get)
    end.to raise_error(ActionController::RoutingError)
  end

  it 'requires authentication to create a contribution' do
    post proposal_proposal_comments_path(proposal), params: { proposal_comment: { content: 'My comment' } }
    expect(response).to redirect_to(new_user_session_path)
  end

  it 'creates a contribution and redirects back to the proposal' do
    sign_in user
    expect do
      post proposal_proposal_comments_path(proposal), params: { proposal_comment: { content: 'My test comment' } }
    end.to change(ProposalComment, :count).by(1)
    expect(response).to redirect_to(proposal_path(proposal))
  end

  it 'renders and updates the edit form for the author' do
    sign_in user
    get edit_proposal_proposal_comment_path(proposal, comment)
    expect(response).to have_http_status(:ok)

    patch proposal_proposal_comment_path(proposal, comment), params: { proposal_comment: { content: 'Updated content' } }
    expect(response).to redirect_to(proposal_path(proposal))
    expect(comment.reload.content).to eq('Updated content')
  end

  it 'destroys the contribution for its author' do
    sign_in user
    expect do
      delete proposal_proposal_comment_path(proposal, comment)
    end.to change(ProposalComment, :count).by(-1)
    expect(response).to redirect_to(proposal_path(proposal))
  end

  it 'renders the list and reply history surfaces without server errors' do
    reply = create(:proposal_comment, proposal: proposal, user: user, contribute: comment)

    get list_proposal_proposal_comments_path(proposal)
    expect(response).to have_http_status(:ok)

    get show_all_replies_proposal_proposal_comment_path(proposal, comment)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(reply.content)
  end

  it 'requires authentication to report a contribution' do
    post report_proposal_proposal_comments_path(proposal), params: { id: comment.id, reason: 1 }
    expect(response).to redirect_to(new_user_session_path)
  end

  it 'returns a Turbo Stream history dialog' do
    sign_in user
    get history_proposal_proposal_comment_path(proposal, comment),
        headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq('text/vnd.turbo-stream.html')
  end

  it 'redirects the modal-only noise pages on direct HTML requests' do
    sign_in user
    get noise_proposal_proposal_comments_path(proposal)
    expect(response).to redirect_to(proposal_path(proposal))

    get manage_noise_proposal_proposal_comments_path(proposal)
    expect(response).to redirect_to(proposal_path(proposal))
  end

  it 'marks noise for the proposal author' do
    sign_in user
    post mark_noise_proposal_proposal_comments_path(proposal),
         params: { comments: { active: '', inactive: comment.id.to_s } },
         headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    expect(response).to have_http_status(:ok)
    expect(comment.reload).to be_noise
  end
end
