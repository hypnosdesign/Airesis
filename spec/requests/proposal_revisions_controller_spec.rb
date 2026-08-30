require 'rails_helper'
require 'requests_helper'

RSpec.describe ProposalRevisionsController, seeds: true do
  let!(:user) { create(:user) }
  let!(:proposal) { create(:public_proposal, current_user_id: user.id) }
  let!(:revision) { ProposalRevision.create!(proposal: proposal, user: user, seq: 1, rank: 0, valutations: 0) }

  it 'requires authentication for revision history' do
    get proposal_proposal_revisions_path(proposal)
    expect(response).to redirect_to(new_user_session_path)
  end

  it 'renders the revision explorer in HTML and Turbo Stream' do
    sign_in user
    get proposal_proposal_revisions_path(proposal)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('proposal_history_version')

    get proposal_proposal_revisions_path(proposal), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq('text/vnd.turbo-stream.html')
  end

  it 'returns the selected revision as a Turbo Stream and redirects direct HTML' do
    sign_in user
    get proposal_proposal_revision_path(proposal, revision), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('diff_container')

    get proposal_proposal_revision_path(proposal, revision)
    expect(response).to redirect_to(proposal_proposal_revisions_path(proposal))
  end
end
