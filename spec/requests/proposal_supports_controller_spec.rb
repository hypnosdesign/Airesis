require 'rails_helper'
require 'requests_helper'

RSpec.describe ProposalSupportsController, seeds: true do
  let!(:user) { create(:user) }
  let!(:proposal) { create(:public_proposal, current_user_id: user.id) }

  it 'does not expose the removed index route' do
    expect do
      Rails.application.routes.recognize_path("/proposals/#{proposal.id}/proposal_supports", method: :get)
    end.to raise_error(ActionController::RoutingError)
  end

  it 'requires authentication for the support form' do
    get new_proposal_proposal_support_path(proposal)
    expect(response).to redirect_to(new_user_session_path)
  end

  it 'renders the support form without the former scoped-groups SQL error' do
    sign_in user
    get new_proposal_proposal_support_path(proposal)
    expect(response).to have_http_status(:ok)
  end

  it 'saves an empty support selection and redirects to the proposal' do
    sign_in user
    post proposal_proposal_supports_path(proposal), params: { proposal: { supporting_group_ids: [] } }
    expect(response).to redirect_to(proposal_path(proposal))
  end
end
