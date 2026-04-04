require 'rails_helper'
require 'requests_helper'

RSpec.describe User::Groupable, seeds: true do
  let!(:user) { create(:user) }
  let!(:group) { create(:group, current_user_id: user.id) }

  describe '#suggested_groups' do
    it 'returns a collection of groups' do
      result = user.suggested_groups
      expect(result).to respond_to(:each)
    end
  end

  describe '#has_asked_for_participation?' do
    it 'returns nil when user has not asked for participation' do
      other_group = create(:group, current_user_id: create(:user).id)
      expect(user.has_asked_for_participation?(other_group.id)).to be_nil
    end

    it 'returns the request when user has asked for participation' do
      other_group = create(:group, current_user_id: create(:user).id)
      GroupParticipationRequest.create!(
        user_id: user.id,
        group_id: other_group.id,
        group_participation_request_status_id: 1
      )
      expect(user.has_asked_for_participation?(other_group.id)).to be_present
    end
  end

  describe '#scoped_group_participations' do
    it 'returns participations with the given abilitation' do
      result = user.scoped_group_participations(:participate_proposals)
      expect(result).to respond_to(:each)
    end
  end

  describe '#scoped_areas' do
    it 'returns areas for a group the user administers' do
      result = user.scoped_areas(group.id)
      expect(result).to respond_to(:each)
    end
  end

  describe 'associations' do
    it 'has groups through group_participations' do
      expect(user.groups).to include(group)
    end

    it 'has portavoce_groups' do
      expect(user.portavoce_groups).to respond_to(:each)
    end

    it 'has group_participation_requests' do
      expect(user.group_participation_requests).to respond_to(:each)
    end

    it 'has followed_groups' do
      expect(user.followed_groups).to respond_to(:each)
    end
  end
end
