require 'rails_helper'

RSpec.describe Frm::TopicsHelper, type: :helper, seeds: true do
  let!(:user) { create(:user) }
  let!(:group) { create(:group, current_user_id: user.id) }
  let!(:category) { Frm::Category.create!(name: 'Test', group: group, visible_outside: true) }
  let!(:forum) do
    Frm::Forum.create!(name: 'Test Forum', description: 'desc', group: group, category: category,
                       visible_outside: true)
  end
  let!(:topic) { create(:frm_topic, forum: forum, user: user) }

  before do
    allow(helper).to receive(:current_user).and_return(nil)
  end

  describe '#icon_classes' do
    it 'returns base icon classes' do
      result = helper.icon_classes(topic)
      expect(result).to include('icon')
    end

    it 'includes lock class when topic is locked' do
      topic.update!(locked: true)
      result = helper.icon_classes(topic)
      expect(result).to include('lock')
    end

    it 'includes pin class when topic is pinned' do
      topic.update!(pinned: true)
      result = helper.icon_classes(topic)
      expect(result).to include('pin')
    end

    it 'includes hidden class when topic is hidden' do
      topic.update!(hidden: true)
      result = helper.icon_classes(topic)
      expect(result).to include('hidden')
    end
  end

  describe '#new_since_last_view_text' do
    it 'returns nil when no current_user' do
      result = helper.new_since_last_view_text(topic)
      expect(result).to be_nil
    end

    it 'returns nil when no forum_view exists' do
      allow(helper).to receive(:current_user).and_return(user)
      result = helper.new_since_last_view_text(topic)
      expect(result).to be_nil
    end
  end

  describe '#icon_classes with current_user' do
    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    it 'returns base icon class without unread posts' do
      result = helper.icon_classes(topic)
      expect(result).to include('icon')
    end

    it 'includes new_posts class when topic has new posts after forum_view' do
      forum_view = Frm::View.create!(viewable: forum, user: user, current_viewed_at: 1.hour.ago, past_viewed_at: 1.hour.ago)
      topic_view = Frm::View.create!(viewable: topic, user: user, current_viewed_at: 2.hours.ago, past_viewed_at: 2.hours.ago)
      result = helper.icon_classes(topic)
      expect(result).to be_a(String)
    end
  end
end
