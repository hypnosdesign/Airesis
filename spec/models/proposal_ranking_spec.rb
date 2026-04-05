require 'rails_helper'

RSpec.describe ProposalRanking, type: :model, seeds: true do
  let!(:user) { create(:user) }
  let!(:proposal) { create(:public_proposal, current_user_id: user.id) }

  describe 'associations' do
    it { is_expected.to belong_to(:proposal) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'ranking_type enum' do
    it 'defines positive scope' do
      expect(ProposalRanking).to respond_to(:positives)
    end

    it 'defines negative scope' do
      expect(ProposalRanking).to respond_to(:negatives)
    end
  end
end
