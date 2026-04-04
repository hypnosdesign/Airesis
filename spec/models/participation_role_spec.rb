require 'rails_helper'

RSpec.describe ParticipationRole, type: :model, seeds: true do
  let!(:user) { create(:user) }
  let!(:group) { create(:group, current_user_id: user.id) }

  describe 'associations' do
    it { is_expected.to belong_to(:group).optional }
    it { is_expected.to have_many(:group_participations) }
  end

  describe 'validations' do
    it 'requires a name' do
      role = ParticipationRole.new(group: group)
      expect(role).not_to be_valid
    end

    it 'is valid with name, description and group' do
      role = ParticipationRole.new(name: 'Test Role', description: 'A test role', group: group)
      expect(role).to be_valid
    end
  end
end
