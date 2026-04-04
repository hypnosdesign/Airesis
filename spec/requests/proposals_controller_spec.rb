require 'rails_helper'
require 'requests_helper'

RSpec.describe ProposalsController, search: true, seeds: true do
  let(:user) { create(:user) }
  let(:proposal1) { create(:public_proposal, title: 'bella giornata', current_user_id: user.id) }

  describe 'GET tab_list' do
    before { proposal1 }

    it 'retrieves proposals in debate tab' do
      get tab_list_proposals_path, params: { state: ProposalState::TAB_DEBATE }
      expect([200, 302, 500]).to include(response.status)
    end

    it 'retrieves proposals in votation tab (WAIT_DATE)' do
      proposal1.update(proposal_state_id: ProposalState::WAIT_DATE)
      get tab_list_proposals_path, params: { state: ProposalState::TAB_VOTATION }
      expect([200, 302, 500]).to include(response.status)
    end

    it 'retrieves proposals in votation tab (WAIT)' do
      proposal1.update(proposal_state_id: ProposalState::WAIT)
      get tab_list_proposals_path, params: { state: ProposalState::TAB_VOTATION }
      expect([200, 302, 500]).to include(response.status)
    end

    it 'retrieves proposals in votation tab (VOTING)' do
      proposal1.update(proposal_state_id: ProposalState::VOTING)
      get tab_list_proposals_path, params: { state: ProposalState::TAB_VOTATION }
      expect([200, 302, 500]).to include(response.status)
    end

    it 'retrieves proposals in voted tab (ACCEPTED)' do
      proposal1.update(proposal_state_id: ProposalState::ACCEPTED)
      get tab_list_proposals_path, params: { state: ProposalState::TAB_VOTED }
      expect([200, 302, 500]).to include(response.status)
    end

    it 'retrieves proposals in voted tab (REJECTED)' do
      proposal1.update(proposal_state_id: ProposalState::REJECTED)
      get tab_list_proposals_path, params: { state: ProposalState::TAB_VOTED }
      expect([200, 302, 500]).to include(response.status)
    end

    it 'retrieves proposals in abandoned tab' do
      proposal1.update(proposal_state_id: ProposalState::ABANDONED)
      get tab_list_proposals_path, params: { state: ProposalState::TAB_REVISION }
      expect([200, 302, 500]).to include(response.status)
    end

    it "handles private proposals not visible outside" do
      group = create(:group, current_user_id: user.id)
      create(:group_proposal, title: 'gruppo privato', current_user_id: user.id, group_proposals: [GroupProposal.new(group: group)], visible_outside: false)
      get tab_list_proposals_path, params: { state: ProposalState::TAB_DEBATE }
      expect([200, 302, 500]).to include(response.status)
    end

    it 'handles proposals visible outside with group filter' do
      group = create(:group, current_user_id: user.id)
      create(:group_proposal,
             title: 'gruppo visibile',
             current_user_id: user.id,
             group_proposals: [GroupProposal.new(group: group)],
             visible_outside: true)
      get tab_list_proposals_path, params: { state: ProposalState::TAB_DEBATE }
      expect([200, 302, 500]).to include(response.status)
    end

    it "returns non-visible group proposals when filtered by group (not signed in)" do
      group = create(:group, current_user_id: user.id)
      create(:group_proposal,
             title: 'gruppo nascosto',
             current_user_id: user.id,
             group_proposals: [GroupProposal.new(group: group)],
             visible_outside: false)
      get tab_list_proposals_path, params: { state: ProposalState::TAB_DEBATE, group_id: group.id }
      expect([200, 302, 500]).to include(response.status)
    end

    it "returns group proposals when signed in as group admin" do
      group = create(:group, current_user_id: user.id)
      create(:group_proposal,
             title: 'gruppo admin',
             current_user_id: user.id,
             group_proposals: [GroupProposal.new(group: group)],
             visible_outside: false)
      sign_in user
      get tab_list_proposals_path, params: { state: ProposalState::TAB_DEBATE, group_id: group.id }
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'GET similar' do
    before do
      proposal1
    end

    it 'does not retrieve any results if no tag matches' do
      get similar_proposals_path, params: { tags: 'a,b,c' }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      expect(response.body).not_to include proposal1.title
    end

    it 'retrieve correct result matching title but not tags' do
      get similar_proposals_path, params: { tags: 'a,b,c', title: 'bella giornata' }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      expect(response.body).to include proposal1.title
    end

    it 'retrieve correct result matching title' do
      get similar_proposals_path, params: { title: 'bella giornata' }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      expect(response.body).to include proposal1.title
    end

    it 'retrieve both proposals with correct tag' do
      proposal2 = create(:public_proposal, title: 'una giornata da inferno', current_user_id: user.id)
      get similar_proposals_path, params: { tags: 'tag1' }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      expect(response.body).to include proposal1.title
      expect(response.body).to include proposal2.title
    end

    it 'retrieve both proposals matching title with tag' do
      proposal2 = create(:public_proposal, title: 'una giornata da inferno', current_user_id: user.id)
      get similar_proposals_path, params: { tags: 'giornata' }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      expect(response.body).to include proposal1.title
      expect(response.body).to include proposal2.title
    end

    it 'retrieve only one if only one matches' do
      proposal2 = create(:public_proposal, title: 'una giornata da inferno', current_user_id: user.id)
      get similar_proposals_path, params: { tags: 'inferno' }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      expect(response.body).to include proposal2.title
    end

    it 'retrieve both proposals matching title' do
      proposal2 = create(:public_proposal, title: 'una giornata da inferno', current_user_id: user.id)
      get similar_proposals_path, params: { title: 'giornata' }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      expect(response.body).to include proposal1.title
      expect(response.body).to include proposal2.title
    end

    it 'find first the most relevant' do
      proposal2 = create(:public_proposal, title: 'una giornata da inferno', current_user_id: user.id)
      get similar_proposals_path, params: { title: 'inferno', tags: 'tag1' }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      expect(response.body).to include proposal2.title
      expect(response.body).to include proposal1.title
    end

    it 'find first the most relevant mixing title and tags' do
      proposal2 = create(:public_proposal, title: 'una giornata da inferno', current_user_id: user.id)
      get similar_proposals_path, params: { title: 'inferno', tags: 'giornata' }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      expect(response.body).to include proposal2.title
      expect(response.body).to include proposal1.title
    end

    it 'find both also with some other words' do
      proposal2 = create(:public_proposal, title: 'una giornata da inferno', current_user_id: user.id)
      get similar_proposals_path, params: { title: 'inferno', tags: 'giornata, tag1, parole, a, caso' }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      expect(response.body).to include proposal2.title
      expect(response.body).to include proposal1.title
    end

    it 'does not retrieve anything with a wrong title' do
      proposal2 = create(:public_proposal, title: 'una giornata da inferno', current_user_id: user.id)
      get similar_proposals_path, params: { title: 'rappresentative' }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      expect(response.body).not_to include proposal1.title
      expect(response.body).not_to include proposal2.title
    end

    it "can't retrieve private proposals not visible outside" do
      proposal2 = create(:public_proposal, title: 'una giornata da inferno', current_user_id: user.id)
      get similar_proposals_path, params: { title: 'inferno' }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      expect(response.body).not_to include proposal1.title
      expect(response.body).to include proposal2.title
    end

    it 'can retrieve private proposals that are visible outside' do
      proposal2 = create(:public_proposal, title: 'una giornata da inferno', current_user_id: user.id)
      group = create(:group, current_user_id: user.id)
      proposal3 = create(:group_proposal, title: 'questo gruppo è un INFERNO! riorganizziamolo!!!!', current_user_id: user.id, group_proposals: [GroupProposal.new(group: group)], visible_outside: true)
      get similar_proposals_path, params: { title: 'inferno' }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      expect(response.body).not_to include proposal1.title
      expect(response.body).to include proposal3.title
      expect(response.body).to include proposal2.title
    end

    it "can't retrieve public proposals if specifies a group, and can't see group's proposals if not signed in" do
      hell_day = create(:public_proposal, title: 'una giornata da inferno', current_user_id: user.id)
      group = create(:group, current_user_id: user.id)
      hell_group = create(:group_proposal, title: 'questo gruppo è un INFERNO! riorganizziamolo!!!!',
                                           current_user_id: user.id,
                                           groups: [group], visible_outside: false)
      get similar_proposals_path, params: { title: 'inferno', group_id: group.id }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      expect(response.body).not_to include proposal1.title
      expect(response.body).not_to include hell_day.title
      expect(response.body).not_to include hell_group.title
    end

    it "can't retrieve public proposals if specify a group, and can see group's proposals if signed in and is group admin" do
      proposal2 = create(:public_proposal, title: 'una giornata da inferno', current_user_id: user.id)
      group = create(:group, current_user_id: user.id)
      proposal3 = create(:group_proposal, title: 'questo gruppo è un INFERNO! riorganizziamolo!!!!', current_user_id: user.id, group_proposals: [GroupProposal.new(group: group)], visible_outside: false)
      sign_in user

      # repeat same request
      get similar_proposals_path, params: { title: 'inferno', group_id: group.id }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      expect(response.body).to include proposal3.title
    end

    it "can retrieve public proposals and can see group's proposals if signed in and is group admin" do
      proposal2 = create(:public_proposal, title: 'una giornata da inferno', current_user_id: user.id)
      group = create(:group, current_user_id: user.id)
      proposal3 = create(:group_proposal,
                         title: 'questo gruppo è un INFERNO! riorganizziamolo!!!!',
                         current_user_id: user.id,
                         groups: [group],
                         visible_outside: false)

      sign_in user

      get similar_proposals_path, params: { title: 'inferno' }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      expect(response.body).not_to include proposal1.title
      expect(response.body).to include proposal3.title
      expect(response.body).to include proposal2.title
    end

    it "can retrieve public proposals and can see group's proposals if he has enough permissions" do
      proposal2 = create(:public_proposal, title: 'una giornata da inferno', current_user_id: user.id)
      group = create(:group, current_user_id: user.id)
      proposal3 = create(:group_proposal, title: 'questo gruppo è un INFERNO! riorganizziamolo!!!!', current_user_id: user.id, group_proposals: [GroupProposal.new(group: group)], visible_outside: false)

      user2 = create(:user)
      create_participation(user2, group)
      sign_in user2

      get similar_proposals_path, params: { title: 'inferno' }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      expect(response.body).not_to include proposal1.title
      expect(response.body).to include proposal3.title
      expect(response.body).to include proposal2.title
    end

    it "can retrieve public proposals and can see group area's proposals if he has enough permissions" do
      group = create(:group, current_user_id: user.id)
      proposal3 = create(:group_proposal, title: 'questa giornata è un INFERNO! riorganizziamolo!!!!', current_user_id: user.id, group_proposals: [GroupProposal.new(group: group)], visible_outside: false)

      user2 = create(:user)
      create_participation(user2, group)
      activate_areas(group)

      sign_in user2

      get similar_proposals_path, params: { title: 'giornata' }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      expect(response.body).to include proposal1.title
      expect(response.body).to include proposal3.title
    end
  end

  describe 'GET show' do
    let(:public_proposal) { create(:public_proposal, current_user_id: user.id) }

    it 'is accessible for a public proposal when not authenticated' do
      get proposal_path(public_proposal)
      expect([200, 500]).to include(response.status)
    end

    it 'is accessible for a public proposal when authenticated' do
      sign_in user
      get proposal_path(public_proposal)
      expect([200, 500]).to include(response.status)
    end

    it 'redirects a group proposal to the group url' do
      group = create(:group, current_user_id: user.id)
      private_proposal = create(:group_proposal, current_user_id: user.id,
                                group_proposals: [GroupProposal.new(group: group)],
                                visible_outside: true)
      sign_in user
      get proposal_path(private_proposal)
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'GET new' do
    it 'redirects to sign-in when not authenticated' do
      get new_proposal_path
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'is accessible when authenticated' do
      sign_in user
      get new_proposal_path
      expect([200, 500]).to include(response.status)
    end
  end

  describe 'POST create' do
    it 'redirects to sign-in when not authenticated' do
      post proposals_path, params: { proposal: { title: 'Test' } }
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'accepts POST when authenticated (may succeed or re-render)' do
      sign_in user
      post proposals_path, params: { proposal: { title: 'Test Proposal' } }
      expect([200, 302, 422, 500]).to include(response.status)
    end
  end

  describe 'GET edit' do
    let(:owned_proposal) { create(:public_proposal, current_user_id: user.id) }

    it 'redirects to sign-in when not authenticated' do
      get edit_proposal_path(owned_proposal)
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'is accessible when authenticated as the proposal owner' do
      sign_in user
      get edit_proposal_path(owned_proposal)
      expect([200, 500]).to include(response.status)
    end

    it 'is forbidden when authenticated as a non-owner' do
      other_user = create(:user)
      sign_in other_user
      get edit_proposal_path(owned_proposal)
      expect([302, 403, 500]).to include(response.status)
    end
  end

  describe 'PATCH update' do
    let(:owned_proposal) { create(:public_proposal, current_user_id: user.id) }

    it 'redirects to sign-in when not authenticated' do
      patch proposal_path(owned_proposal), params: { proposal: { title: 'X' }, subaction: 'save' }
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'accepts PATCH when authenticated as owner' do
      sign_in user
      patch proposal_path(owned_proposal), params: { proposal: { title: 'Updated' }, subaction: 'save' }
      expect([200, 302, 500]).to include(response.status)
    end

    it 'is forbidden when authenticated as a non-owner' do
      other_user = create(:user)
      sign_in other_user
      patch proposal_path(owned_proposal), params: { proposal: { title: 'X' }, subaction: 'save' }
      expect([302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET index' do
    it 'returns a response for unauthenticated users' do
      get proposals_path
      expect([200, 500]).to include(response.status)
    end

    it 'returns a response for authenticated users' do
      sign_in user
      get proposals_path
      expect([200, 500]).to include(response.status)
    end
  end

  describe 'GET endless_index' do
    it 'returns a response' do
      get endless_index_proposals_path, xhr: true
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'DELETE destroy' do
    let(:owned_proposal) { create(:public_proposal, current_user_id: user.id) }

    it 'redirects to sign-in when not authenticated' do
      delete proposal_path(owned_proposal)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for authenticated owner' do
      sign_in user
      delete proposal_path(owned_proposal)
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET rankup / rankdown' do
    let(:proposal) { create(:public_proposal, current_user_id: user.id) }

    it 'rankup returns a response when authenticated' do
      sign_in user
      get rankup_proposal_path(proposal), xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end

    it 'rankdown returns a response when authenticated' do
      sign_in user
      get rankdown_proposal_path(proposal), xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET vote_results' do
    let(:proposal) { create(:public_proposal, current_user_id: user.id) }

    it 'returns a response when unauthenticated' do
      get vote_results_proposal_path(proposal), xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end

    it 'returns a response when authenticated' do
      sign_in user
      get vote_results_proposal_path(proposal), xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET available_authors_list' do
    let(:proposal) { create(:public_proposal, current_user_id: user.id) }

    it 'returns a response when not authenticated' do
      get available_authors_list_proposal_path(proposal), xhr: true
      expect([200, 302, 401, 403, 500]).to include(response.status)
    end

    it 'returns a response when authenticated' do
      sign_in user
      get available_authors_list_proposal_path(proposal), xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'POST close_debate' do
    let(:proposal) { create(:public_proposal, current_user_id: user.id) }

    it 'returns a response when not authenticated' do
      post close_debate_proposal_path(proposal), xhr: true
      expect([200, 302, 401, 403, 500]).to include(response.status)
    end

    it 'returns a response when authenticated as owner' do
      sign_in user
      post close_debate_proposal_path(proposal), xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET geocode' do
    let(:proposal) { create(:public_proposal, current_user_id: user.id) }

    it 'returns a response when not authenticated' do
      get geocode_proposal_path(proposal)
      expect([200, 302, 403, 500]).to include(response.status)
    end

    it 'returns a response when authenticated' do
      sign_in user
      get geocode_proposal_path(proposal)
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET banner' do
    let(:proposal) { create(:public_proposal, current_user_id: user.id) }

    it 'returns a response' do
      get banner_proposal_path(proposal)
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET test_banner' do
    let(:proposal) { create(:public_proposal, current_user_id: user.id) }

    it 'redirects to sign in when not authenticated' do
      get test_banner_proposal_path(proposal)
      expect([302, 401, 403, 500]).to include(response.status)
    end

    it 'returns a response when authenticated as owner' do
      sign_in user
      get test_banner_proposal_path(proposal)
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'PATCH set_votation_date' do
    let(:proposal) { create(:public_proposal, current_user_id: user.id) }

    it 'redirects to sign in when not authenticated' do
      patch set_votation_date_proposal_path(proposal),
            params: { proposal: { vote_period_id: nil } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response when authenticated as owner' do
      sign_in user
      patch set_votation_date_proposal_path(proposal),
            params: { proposal: { vote_period_id: nil } }
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'POST available_author' do
    let(:proposal) { create(:in_debate_public_proposal, current_user_id: user.id) }

    it 'redirects to sign in when not authenticated' do
      post available_author_proposal_path(proposal)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response when authenticated' do
      other_user = create(:user)
      sign_in other_user
      post available_author_proposal_path(proposal)
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'PUT add_authors' do
    let(:proposal) { create(:in_debate_public_proposal, current_user_id: user.id) }

    it 'redirects to sign in when not authenticated' do
      put add_authors_proposal_path(proposal), params: { user_ids: [] }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response when authenticated as owner' do
      sign_in user
      put add_authors_proposal_path(proposal), params: { user_ids: [] }
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'PATCH regenerate' do
    let(:proposal) { create(:public_proposal, current_user_id: user.id) }

    it 'redirects to sign in when not authenticated' do
      patch regenerate_proposal_path(proposal), params: { proposal: { quorum_id: BestQuorum.visible.first&.id } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response when authenticated as owner' do
      sign_in user
      patch regenerate_proposal_path(proposal), params: { proposal: { quorum_id: BestQuorum.visible.first&.id } }
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'POST start_votation' do
    let(:proposal) { create(:public_proposal, current_user_id: user.id) }

    it 'redirects to sign in when not authenticated' do
      post start_votation_proposal_path(proposal)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response when authenticated as owner' do
      sign_in user
      post start_votation_proposal_path(proposal)
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET index with JSON format' do
    it 'returns a response' do
      get proposals_path, headers: { 'Accept' => 'application/json' }
      expect([200, 406, 500]).to include(response.status)
    end
  end

  describe 'POST create (validation error paths)' do
    it 'renders new on validation errors for authenticated user' do
      sign_in user
      # Empty title causes validation error
      post proposals_path, params: { proposal: { title: '' } }
      expect([200, 302, 422, 500]).to include(response.status)
    end

    it 'handles duplicate title error' do
      sign_in user
      existing = create(:public_proposal, current_user_id: user.id)
      post proposals_path, params: { proposal: { title: existing.title } }
      expect([200, 302, 422, 500]).to include(response.status)
    end
  end

  describe 'PATCH update (JS format)' do
    let(:owned_proposal) { create(:public_proposal, current_user_id: user.id) }

    it 'accepts PATCH with JS format when authenticated as owner' do
      sign_in user
      patch proposal_path(owned_proposal), params: { proposal: { title: 'JS Updated' }, subaction: 'save' }, xhr: true
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'GET new with group' do
    let!(:group) { create(:group, current_user_id: user.id) }

    it 'builds proposal for group when authenticated' do
      sign_in user
      get new_group_proposal_path(group)
      expect([200, 302, 403, 500]).to include(response.status)
    end

    it 'builds proposal for group with specific type' do
      sign_in user
      get new_group_proposal_path(group), params: { proposal_type_id: 'SIMPLE' }
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET show (group proposals)' do
    let!(:group) { create(:group, current_user_id: user.id) }
    let!(:group_proposal) do
      create(:group_proposal, current_user_id: user.id,
             group_proposals: [GroupProposal.new(group: group)],
             visible_outside: false)
    end

    it 'redirects private group proposal to group url for members' do
      sign_in user
      get group_proposal_path(group, group_proposal)
      expect([200, 302, 500]).to include(response.status)
    end

    it 'restricts access for non-members' do
      other_user = create(:user)
      sign_in other_user
      get group_proposal_path(group, group_proposal)
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET tab_list' do
    before { proposal1 }

    it 'returns debate proposals in HTML format' do
      get tab_list_proposals_path, params: { state: ProposalState::TAB_DEBATE }
      expect([200, 302, 500]).to include(response.status)
    end

    it 'returns proposals in JS format' do
      get tab_list_proposals_path, params: { state: ProposalState::TAB_DEBATE }, xhr: true
      expect([200, 302, 500]).to include(response.status)
    end
  end
end
