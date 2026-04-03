require 'rails_helper'

RSpec.describe GroupArea, type: :model, seeds: true do
  let!(:user) { create(:user) }
  let!(:group) { create(:group, current_user_id: user.id) }

  describe 'creation' do
    it 'creates a group area with a default role' do
      area = create(:group_area, group: group)
      expect(area).to be_persisted
      expect(area.default_area_role).to be_present
    end

    it 'creates the default area role with the given name' do
      area = create(:group_area, group: group, default_role_name: 'Members')
      expect(area.area_roles.first.name).to eq 'Members'
    end

    it 'assigns DEFAULT_AREA_ACTIONS to the default role after creation' do
      area = create(:group_area, group: group)
      role = area.default_area_role
      DEFAULT_AREA_ACTIONS.each do |action|
        expect(role[action]).to be_truthy
      end
    end
  end

  describe 'validations' do
    it 'requires a name with at least 3 characters' do
      area = GroupArea.new(group: group, default_role_name: 'test', name: 'ab', description: 'valid')
      expect(area).not_to be_valid
    end

    it 'requires group_id' do
      area = GroupArea.new(default_role_name: 'test', name: 'Valid Name')
      expect(area).not_to be_valid
    end

    it 'requires unique name within the same group' do
      create(:group_area, group: group, name: 'UniqueArea')
      area2 = GroupArea.new(group: group, default_role_name: 'test', name: 'UniqueArea')
      expect(area2).not_to be_valid
    end

    it 'allows same name in different groups' do
      group2 = create(:group, current_user_id: user.id)
      create(:group_area, group: group, name: 'SharedName')
      area2 = build(:group_area, group: group2, name: 'SharedName')
      expect(area2).to be_valid
    end
  end

  describe '#scoped_participants' do
    let(:area) { create(:group_area, group: group) }

    it 'returns participants who have the specified action permission' do
      participant = create(:user)
      create_participation(participant, group)
      area.area_participations.create!(user: participant, area_role_id: area.area_role_id)
      # default role has all actions enabled
      expect(area.scoped_participants('insert_proposals')).to include(participant)
    end
  end

  describe '#to_param' do
    it 'returns id-slug format' do
      area = create(:group_area, group: group, name: 'My Area')
      expect(area.to_param).to match(/^\d+-my-area$/)
    end

    it 'strips special characters' do
      area = create(:group_area, group: group, name: 'Area & Test!')
      expect(area.to_param).to match(/^\d+-area-test$/)
    end
  end

  describe '#destroy' do
    it 'removes the area_role_id before destroying' do
      area = create(:group_area, group: group)
      area_id = area.id
      area.destroy
      expect(GroupArea.find_by(id: area_id)).to be_nil
    end
  end
end
