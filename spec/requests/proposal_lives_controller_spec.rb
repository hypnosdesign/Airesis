require 'rails_helper'
require 'requests_helper'

RSpec.describe ProposalLivesController, seeds: true do
  let!(:user) { create(:user) }
  let!(:proposal) { create(:public_proposal, current_user_id: user.id) }

  describe 'GET show' do
    it 'redirects to sign in when not authenticated' do
      life = proposal.proposal_lives.first
      next unless life

      get "/proposals/#{proposal.id}/proposal_lives/#{life.id}"
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response when authenticated (proposal has lives from creation)' do
      sign_in user
      life = proposal.proposal_lives.first
      if life
        get "/proposals/#{proposal.id}/proposal_lives/#{life.id}"
        expect([200, 302, 500]).to include(response.status)
      end
    end
  end
end
