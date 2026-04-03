require 'rails_helper'
require 'requests_helper'
require 'cancan/matchers'

RSpec.describe 'Proposal abilities', type: :model, seeds: true do
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:group_owner) { create(:user) }
  let!(:group) { create(:group, current_user_id: group_owner.id) }

  describe 'public proposals' do
    let(:ability) { Ability.new(user) }
    let!(:proposal) { create(:public_proposal, current_user_id: user.id) }

    it 'can create a public proposal' do
      expect(ability).to be_able_to(:create, Proposal.new)
    end

    it 'can read a public proposal' do
      expect(ability).to be_able_to(:read, proposal)
    end

    it 'can participate in a public proposal' do
      expect(ability).to be_able_to(:participate, proposal)
    end
  end

  describe 'proposal comments' do
    let(:ability) { Ability.new(user) }
    let!(:proposal) { create(:public_proposal, current_user_id: user.id) }

    it 'can create comments on public proposals' do
      comment = ProposalComment.new(proposal: proposal, user: user)
      expect(ability).to be_able_to(:create, comment)
    end

    it 'can update own comments' do
      comment = create(:proposal_comment, proposal: proposal, user: user)
      expect(ability).to be_able_to(:update, comment)
    end

    it 'cannot update other users comments' do
      comment = create(:proposal_comment, proposal: proposal, user: other_user)
      expect(ability).not_to be_able_to(:update, comment)
    end
  end

  describe 'group proposals' do
    let(:member) { create(:user) }
    let!(:member_participation) { create_participation(member, group) }
    let(:member_ability) { Ability.new(member) }
    let(:outsider_ability) { Ability.new(user) }

    context 'proposal not visible outside' do
      let!(:proposal) do
        create(:group_proposal, current_user_id: group_owner.id,
               groups: [group], visible_outside: false)
      end

      it 'member can read the proposal' do
        expect(member_ability).to be_able_to(:read, proposal)
      end

      it 'outsider cannot read the proposal' do
        expect(outsider_ability).not_to be_able_to(:read, proposal)
      end
    end

    context 'proposal visible outside' do
      let!(:proposal) do
        create(:group_proposal, current_user_id: group_owner.id,
               groups: [group], visible_outside: true)
      end

      it 'member can read the proposal' do
        expect(member_ability).to be_able_to(:read, proposal)
      end

      it 'outsider can read the proposal' do
        expect(outsider_ability).to be_able_to(:read, proposal)
      end
    end
  end

  describe 'ProposalSupport' do
    let(:ability) { Ability.new(user) }

    it 'can create a new proposal support' do
      expect(ability).to be_able_to(:new, ProposalSupport)
    end
  end
end
