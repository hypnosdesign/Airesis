require 'rails_helper'
require 'requests_helper'

RSpec.describe ProposalLivesController, seeds: true do
  let!(:user) { create(:user) }
  let!(:proposal) { create(:public_proposal, current_user_id: user.id) }
  let!(:life) { ProposalLife.create!(proposal: proposal, quorum: proposal.quorum, seq: 1, rank: 0, valutations: 0) }

  it 'requires authentication for a lifecycle snapshot' do
    get proposal_proposal_life_path(proposal, life)
    expect(response).to redirect_to(new_user_session_path)
  end

  it 'returns a lifecycle snapshot as Turbo Stream and redirects direct HTML' do
    sign_in user
    get proposal_proposal_life_path(proposal, life), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('diff_container')

    get proposal_proposal_life_path(proposal, life)
    expect(response).to redirect_to(proposal_proposal_revisions_path(proposal))
  end
end
