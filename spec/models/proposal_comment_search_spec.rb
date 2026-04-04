require 'rails_helper'

RSpec.describe ProposalCommentSearch, type: :model, seeds: true do
  let!(:user) { create(:user) }
  let!(:proposal) { create(:public_proposal, current_user_id: user.id) }

  describe '#initialize' do
    it 'creates a search with default params' do
      search = described_class.new({}, proposal)
      expect(search).to be_a(ProposalCommentSearch)
    end

    it 'accepts view and page params' do
      search = described_class.new({ view: SearchProposal::ORDER_RANDOM, page: 1 }, proposal, user)
      expect(search.random_order?).to be true
    end
  end

  describe '#random_order?' do
    it 'returns true when view is ORDER_RANDOM' do
      search = described_class.new({ view: SearchProposal::ORDER_RANDOM }, proposal)
      expect(search.random_order?).to be true
    end

    it 'returns false when view is not ORDER_RANDOM' do
      search = described_class.new({}, proposal)
      expect(search.random_order?).to be false
    end
  end

  describe '#rank_order?' do
    it 'returns true when view is ORDER_BY_RANK' do
      search = described_class.new({ view: SearchProposal::ORDER_BY_RANK }, proposal)
      expect(search.rank_order?).to be true
    end

    it 'returns false for other views' do
      search = described_class.new({}, proposal)
      expect(search.rank_order?).to be false
    end
  end

  describe '#evaluated_ids' do
    it 'returns empty array when no current_user' do
      search = described_class.new({}, proposal, nil)
      expect(search.evaluated_ids).to eq []
    end

    it 'returns array when current_user is set' do
      search = described_class.new({}, proposal, user)
      expect(search.evaluated_ids).to be_an(Array)
    end
  end

  describe '#order_clause' do
    it 'returns an order clause string' do
      search = described_class.new({}, proposal)
      expect(search.order_clause).to be_a(String)
    end
  end

  describe '#proposal_comments' do
    it 'returns a relation' do
      search = described_class.new({ all: '1' }, proposal)
      expect(search.proposal_comments).to respond_to(:each)
    end

    it 'memoizes the result' do
      search = described_class.new({ all: '1' }, proposal)
      first_call = search.proposal_comments
      second_call = search.proposal_comments
      expect(first_call.object_id).to eq second_call.object_id
    end
  end
end
