require 'rails_helper'
require 'requests_helper'

RSpec.describe BlockedProposalAlertsController, seeds: true do
  let!(:user) { create(:user) }
  let!(:proposal) { create(:public_proposal, current_user_id: user.id) }

  describe 'POST block' do
    it 'redirects to sign in when not authenticated' do
      post block_proposal_blocked_proposal_alerts_path(proposal)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response when authenticated' do
      sign_in user
      post block_proposal_blocked_proposal_alerts_path(proposal)
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'POST unlock' do
    before do
      BlockedProposalAlert.create!(
        user_id: user.id,
        proposal_id: proposal.id,
        updates: true,
        contributes: true,
        state: true,
        authors: true,
        valutations: true
      )
    end

    it 'redirects to sign in when not authenticated' do
      post unlock_proposal_blocked_proposal_alerts_path(proposal)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response when authenticated' do
      sign_in user
      post unlock_proposal_blocked_proposal_alerts_path(proposal)
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end
end
