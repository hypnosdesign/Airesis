require 'rails_helper'

RSpec.describe User::Proposable, type: :model, seeds: true do
  let!(:user) { create(:user) }
  let!(:proposal) { create(:public_proposal, current_user_id: user.id) }
  let!(:comment) { create(:proposal_comment, proposal: proposal, user: user) }

  describe '#last_proposal_comment' do
    it 'returns the most recent proposal comment' do
      expect(user.last_proposal_comment).to eq comment
    end

    it 'returns nil when user has no comments' do
      other_user = create(:user)
      expect(other_user.last_proposal_comment).to be_nil
    end
  end

  describe '#is_my_proposal?' do
    it 'returns true when the proposal belongs to the user' do
      expect(user.is_my_proposal?(proposal.id)).to be true
    end

    it 'returns false when the proposal does not belong to the user' do
      other_user = create(:user)
      expect(other_user.is_my_proposal?(proposal.id)).to be false
    end
  end

  describe '#has_ranked_proposal?' do
    it 'returns false when user has not ranked the proposal' do
      expect(user.has_ranked_proposal?(proposal.id)).to be false
    end
  end

  describe '#comment_rank' do
    it 'returns nil when the user has not ranked the comment' do
      expect(user.comment_rank(comment)).to be_nil
    end
  end

  describe '#can_rank_again_comment?' do
    it 'returns true when user has never ranked the comment' do
      other_user = create(:user)
      expect(other_user.can_rank_again_comment?(comment)).to be true
    end
  end
end
