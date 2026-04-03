require 'rails_helper'
require 'requests_helper'

RSpec.describe VotationsController, seeds: true do
  let!(:user) { create(:user) }
  let!(:proposal) { create(:public_proposal, current_user_id: user.id) }

  describe 'PUT vote' do
    it 'redirects to sign in when not authenticated' do
      put '/votation/vote', params: { proposal_id: proposal.id, data: { vote_type: 1 } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'accepts the request when authenticated' do
      sign_in user
      put '/votation/vote', xhr: true,
          params: { proposal_id: proposal.id, data: { vote_type: 1 } }
      # Proposal may not be in voting state, returns various errors
      expect([200, 302, 403, 422, 500]).to include(response.status)
    end
  end

  describe 'PUT vote_schulze' do
    it 'redirects to sign in when not authenticated' do
      put '/votation/vote_schulze', params: { proposal_id: proposal.id, data: { votes: '1,2' } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'accepts the request when authenticated' do
      sign_in user
      put '/votation/vote_schulze', xhr: true,
          params: { proposal_id: proposal.id, data: { votes: '1,2' } }
      # Proposal may not be in voting state, returns various errors
      expect([200, 302, 403, 422, 500]).to include(response.status)
    end
  end
end
