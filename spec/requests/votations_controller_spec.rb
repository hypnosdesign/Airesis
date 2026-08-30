require 'rails_helper'
require 'requests_helper'

RSpec.describe VotationsController, seeds: true do
  let!(:user) { create(:user) }
  let!(:proposal) { create(:public_proposal, current_user_id: user.id) }

  it 'exposes the voting commands and redirects the legacy landing page' do
    expect(Rails.application.routes.recognize_path('/votation/vote', method: :put)).to include(controller: 'votations', action: 'vote')
    expect(Rails.application.routes.recognize_path('/votation/vote_schulze', method: :put)).to include(controller: 'votations', action: 'vote_schulze')
    expect(Rails.application.routes.recognize_path('/votation', method: :get)[:controller]).not_to eq('votations')
    expect(Rails.application.routes.recognize_path('/votations', method: :get)[:controller]).not_to eq('votations')

    get legacy_votation_path
    expect(response).to redirect_to('/public')
  end

  it 'requires authentication for a standard vote' do
    put votation_vote_path, params: { proposal_id: proposal.id, data: { vote_type: VoteType::POSITIVE } }
    expect(response).to redirect_to(new_user_session_path)
  end

  it 'rejects a vote outside the voting phase without a server error' do
    sign_in user
    put votation_vote_path, params: { proposal_id: proposal.id, data: { vote_type: VoteType::POSITIVE } }
    expect(response).to have_http_status(:forbidden)
  end

  it 'records a standard vote and redirects to the proposal' do
    voting_proposal = create(:in_vote_public_proposal, current_user_id: user.id)
    sign_in user

    expect do
      put votation_vote_path, params: { proposal_id: voting_proposal.id, data: { vote_type: VoteType::POSITIVE } }
    end.to change { voting_proposal.reload.vote.positive }.by(1)
    expect(response).to redirect_to(proposal_path(voting_proposal))
  end

  it 'requires authentication for a Schulze vote' do
    put votation_vote_schulze_path, params: { proposal_id: proposal.id, data: { votes: proposal.solutions.pluck(:id).join(',') } }
    expect(response).to redirect_to(new_user_session_path)
  end

  it 'records a Schulze ranking and redirects to the proposal' do
    voting_proposal = create(:in_vote_public_proposal, current_user_id: user.id)
    ranking = voting_proposal.solutions.order(:id).pluck(:id).join(',')
    sign_in user

    expect do
      put votation_vote_schulze_path, params: { proposal_id: voting_proposal.id, data: { votes: ranking } }
    end.to change(ProposalSchulzeVote, :count).by(1)
    expect(response).to redirect_to(proposal_path(voting_proposal))
  end
end
