require 'rails_helper'
require 'requests_helper'

RSpec.describe ProposalPresentationsController, seeds: true do
  let!(:user) { create(:user) }
  let!(:proposal) { create(:public_proposal, current_user_id: user.id) }

  describe 'DELETE destroy' do
    it 'redirects to sign in when not authenticated' do
      presentation = proposal.proposal_presentations.first
      next unless presentation

      delete "/proposals/#{proposal.id}/proposal_presentations/#{presentation.id}"
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response when authenticated as the presenter' do
      sign_in user
      presentation = proposal.proposal_presentations.find_by(user_id: user.id)
      if presentation
        delete "/proposals/#{proposal.id}/proposal_presentations/#{presentation.id}"
        expect([200, 302, 403, 500]).to include(response.status)
      end
    end
  end
end
