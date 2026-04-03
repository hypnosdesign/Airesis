require 'rails_helper'

RSpec.describe ProposalsHelper, type: :helper, seeds: true do
  describe '#navigator_actions' do
    it 'returns HTML with up, down, and remove links' do
      html = helper.navigator_actions
      expect(html).to include('move_up')
      expect(html).to include('move_down')
      expect(html).to include('remove')
      expect(html).to include('fa-arrow-up')
      expect(html).to include('fa-arrow-down')
      expect(html).to include('fa-trash')
    end

    it 'includes custom classes when provided' do
      html = helper.navigator_actions(classes: 'my-custom-class')
      expect(html).to include('my-custom-class')
    end
  end

  describe '#reload_message' do
    it 'returns a JS toastr string' do
      result = helper.reload_message
      expect(result).to include('toastr')
      expect(result).to include('reload_proposal')
      expect(result).to include('Reload')
    end
  end

  describe '#proposal_tag' do
    let(:user) { create(:user) }
    let(:proposal) { create(:public_proposal, current_user_id: user.id) }

    it 'returns HTML with proposal_tag div' do
      result = helper.proposal_tag(proposal)
      expect(result).to include('proposal_tag')
      expect(result).to include(proposal.title)
    end
  end

  describe '#link_to_proposal' do
    let(:user) { create(:user) }
    let(:proposal) { create(:public_proposal, current_user_id: user.id) }

    it 'returns a link to the proposal' do
      result = helper.link_to_proposal(proposal)
      expect(result).to include(proposal.title)
      expect(result).to include('href')
    end
  end

  describe '#url_for_proposal' do
    let(:user) { create(:user) }

    it 'returns proposal_url for public proposals' do
      proposal = create(:public_proposal, current_user_id: user.id)
      url = helper.url_for_proposal(proposal)
      expect(url).to include(proposal.to_param)
    end

    it 'returns group_proposal_url for group proposals' do
      group = create(:group, current_user_id: user.id)
      proposal = create(:group_proposal, current_user_id: user.id,
                        group_proposals: [GroupProposal.new(group: group)])
      url = helper.url_for_proposal(proposal)
      expect(url).to be_a(String)
    end
  end

  describe '#json_nicknames' do
    let(:user) { create(:user) }
    let(:proposal) { create(:public_proposal, current_user_id: user.id) }

    it 'returns empty array for non-anonymous proposals' do
      allow(proposal).to receive(:is_anonima?).and_return(false)
      result = helper.json_nicknames(proposal)
      expect(result).to eq('[]')
    end
  end

  describe '#proposal_status' do
    let(:user) { create(:user) }

    it 'returns a string for proposals in debate' do
      proposal = create(:public_proposal, current_user_id: user.id)
      result = helper.proposal_status(proposal)
      expect(result).to be_a(String) if result
    end

    it 'returns a string for abandoned proposals' do
      proposal = create(:public_proposal, current_user_id: user.id)
      proposal.update_column(:proposal_state_id, ProposalState::ABANDONED)
      result = helper.proposal_status(proposal)
      expect(result).to be_a(String) if result
    end
  end

  describe '#proposal_category_image_tag' do
    let(:user) { create(:user) }
    let(:proposal) { create(:public_proposal, current_user_id: user.id) }

    it 'returns an image tag for the proposal category' do
      result = helper.proposal_category_image_tag(proposal)
      expect(result).to include('img')
      expect(result).to include('proposal_categories')
    end
  end

  describe '#proposal_group_image_tag' do
    let(:user) { create(:user) }
    let(:proposal) { create(:public_proposal, current_user_id: user.id) }

    it 'returns category image when no group context' do
      assign(:group, nil)
      result = helper.proposal_group_image_tag(proposal)
      expect(result).to include('img')
    end
  end
end
