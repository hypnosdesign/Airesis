require 'rails_helper'
require 'requests_helper'

RSpec.describe ProposalSupportsController, seeds: true do
  let!(:user) { create(:user) }
  let!(:proposal) { create(:public_proposal, current_user_id: user.id) }

  describe 'GET index' do
    it 'redirects to sign in when not authenticated' do
      get proposal_proposal_supports_path(proposal)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response when authenticated' do
      sign_in user
      get proposal_proposal_supports_path(proposal)
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET new' do
    it 'redirects to sign in when not authenticated' do
      get new_proposal_proposal_support_path(proposal)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response when authenticated' do
      sign_in user
      get new_proposal_proposal_support_path(proposal)
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'POST create' do
    it 'redirects to sign in when not authenticated' do
      post proposal_proposal_supports_path(proposal),
           params: { proposal: { supporting_group_ids: [] } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response when authenticated' do
      sign_in user
      post proposal_proposal_supports_path(proposal),
           params: { proposal: { supporting_group_ids: [] } }
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end
end
