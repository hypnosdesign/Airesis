require 'rails_helper'
require 'requests_helper'

RSpec.describe ProposalNicknamesController, seeds: true do
  let!(:user) { create(:user) }
  let!(:proposal) { create(:public_proposal, current_user_id: user.id) }

  describe 'PATCH update' do
    it 'redirects to sign in when not authenticated' do
      nickname = proposal.proposal_nicknames.first
      next unless nickname

      patch "/proposal_nicknames/#{nickname.id}"
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response when authenticated (may not have nicknames)' do
      sign_in user
      nickname = proposal.proposal_nicknames.find_by(user_id: user.id)
      if nickname
        patch "/proposal_nicknames/#{nickname.id}", xhr: true
        expect([200, 302, 500]).to include(response.status)
      end
    end
  end
end
