require 'rails_helper'

RSpec.describe GroupParticipation, type: :model, seeds: true do
  let!(:user) { create(:user) }
  let!(:group) { create(:group, current_user_id: user.id) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:participation_role) }
  end

  describe 'scopes' do
    it 'can find participations' do
      expect(GroupParticipation.where(group: group).count).to be >= 1
    end
  end
end
