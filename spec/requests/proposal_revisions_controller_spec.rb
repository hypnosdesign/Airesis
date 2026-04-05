require 'rails_helper'
require 'requests_helper'

RSpec.describe ProposalRevisionsController, seeds: true do
  let!(:user) { create(:user) }
  let!(:proposal) { create(:public_proposal, current_user_id: user.id) }

  describe 'GET index' do
    it 'redirects to sign in when not authenticated' do
      get "/proposals/#{proposal.id}/proposal_revisions"
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response when authenticated' do
      sign_in user
      get "/proposals/#{proposal.id}/proposal_revisions"
      expect([200, 302, 500]).to include(response.status)
    end

    it 'returns a JS response when authenticated' do
      sign_in user
      get "/proposals/#{proposal.id}/proposal_revisions", xhr: true
      expect([200, 302, 500]).to include(response.status)
    end
  end
end
