require 'rails_helper'
require 'requests_helper'

RSpec.describe User::Forumable, seeds: true do
  let!(:user) { create(:user) }

  describe 'associations' do
    it 'has viewed_topics' do
      expect(user.viewed_topics).to respond_to(:each)
    end

    it 'has unread_topics' do
      expect(user.unread_topics).to respond_to(:each)
    end

    it 'has memberships' do
      expect(user.memberships).to respond_to(:each)
    end
  end

  describe '#can_read_forem_category?' do
    let!(:group) { create(:group, current_user_id: user.id) }

    it 'returns true when category is visible outside' do
      category = Frm::Category.create!(name: 'Test Category', group: group, visible_outside: true)
      expect(user.can_read_forem_category?(category)).to be_truthy
    end

    it 'returns true when user is a participant in the group' do
      category = Frm::Category.create!(name: 'Test Category', group: group, visible_outside: false)
      expect(user.can_read_forem_category?(category)).to be_truthy
    end
  end

  describe '#can_read_forem_forum?' do
    let!(:group) { create(:group, current_user_id: user.id) }

    it 'returns true when forum is visible outside' do
      category = Frm::Category.create!(name: 'Test Category', group: group, visible_outside: true)
      forum = Frm::Forum.create!(name: 'Test Forum', description: 'desc', group: group, category: category, visible_outside: true)
      expect(user.can_read_forem_forum?(forum)).to be_truthy
    end

    it 'returns false when not visible and not participant' do
      other_user = create(:user)
      category = Frm::Category.create!(name: 'Test Category', group: group, visible_outside: false)
      forum = Frm::Forum.create!(name: 'Test Forum', description: 'desc', group: group, category: category, visible_outside: false)
      expect(other_user.can_read_forem_forum?(forum)).to be_falsey
    end
  end

  describe '#can_create_forem_topics?' do
    let!(:group) { create(:group, current_user_id: user.id) }

    it 'returns false for non-participant' do
      other_user = create(:user)
      category = Frm::Category.create!(name: 'Test Category', group: group, visible_outside: true)
      forum = Frm::Forum.create!(name: 'Test Forum', description: 'desc', group: group, category: category, visible_outside: true)
      expect(other_user.can_create_forem_topics?(forum)).to be_falsey
    end
  end
end
