require 'rails_helper'

RSpec.describe ProposalVote, type: :model, seeds: true do
  let(:user) { create(:user) }
  let(:proposal) { create(:public_proposal, current_user_id: user.id) }
  let(:vote) { proposal.vote || proposal.create_vote!(positive: 0, negative: 0, neutral: 0) }

  describe '#number' do
    it 'returns total of positive, negative, and neutral' do
      vote.update_columns(positive: 5, negative: 3, neutral: 2)
      expect(vote.number).to eq(10)
    end

    it 'returns 0 when all are zero' do
      vote.update_columns(positive: 0, negative: 0, neutral: 0)
      expect(vote.number).to eq(0)
    end
  end

  describe '#positive_perc' do
    it 'returns the positive percentage' do
      vote.update_columns(positive: 7, negative: 2, neutral: 1)
      expect(vote.positive_perc).to eq(70.0)
    end

    it 'returns 0 when no votes' do
      vote.update_columns(positive: 0, negative: 0, neutral: 0)
      expect(vote.positive_perc).to eq(0)
    end
  end

  describe '#negative_perc' do
    it 'returns the negative percentage' do
      vote.update_columns(positive: 7, negative: 2, neutral: 1)
      expect(vote.negative_perc).to eq(20.0)
    end
  end

  describe '#neutral_perc' do
    it 'returns the neutral percentage' do
      vote.update_columns(positive: 7, negative: 2, neutral: 1)
      expect(vote.neutral_perc).to eq(10.0)
    end
  end
end
