require 'rails_helper'

RSpec.describe UserVote, type: :model, seeds: true do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:proposal) }
    it { is_expected.to belong_to(:vote_type).optional }
  end

  describe 'validations' do
    it 'prevents duplicate votes' do
      user = create(:user)
      proposal = create(:public_proposal, current_user_id: user.id)
      UserVote.create!(user: user, proposal: proposal)
      duplicate = UserVote.new(user: user, proposal: proposal)
      expect(duplicate).not_to be_valid
    end
  end
end
