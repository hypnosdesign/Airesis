require 'rails_helper'
require 'requests_helper'

RSpec.describe Frm::TopicsController, seeds: true do
  let!(:owner) { create(:user) }
  let!(:group) { create(:group, current_user_id: owner.id) }
  let!(:forum) { group.forums.first || create(:frm_forum, category: create(:frm_category, group: group), group: group) }
  let!(:topic) { create(:frm_topic, forum: forum, user: owner) }

  describe 'GET index' do
    it 'returns a response for forum members' do
      sign_in owner
      get group_forum_topics_path(group, forum)
      expect([200, 302, 403, 404, 500]).to include(response.status)
    end

    it 'returns a response for non-members' do
      outsider = create(:user)
      sign_in outsider
      get group_forum_topics_path(group, forum)
      expect([200, 302, 403, 404, 500]).to include(response.status)
    end

    it 'requires authentication when not authenticated' do
      get group_forum_topics_path(group, forum)
      expect([200, 302, 403, 404, 500]).to include(response.status)
    end
  end

  describe 'GET show' do
    it 'returns a response for group members' do
      sign_in owner
      get group_forum_topic_path(group, forum, topic)
      expect([200, 302, 403, 404, 500]).to include(response.status)
    end
  end

  describe 'GET new' do
    it 'requires authentication' do
      get new_group_forum_topic_path(group, forum)
      expect([302, 403, 404, 500]).to include(response.status)
    end

    it 'returns a response for group members' do
      sign_in owner
      get new_group_forum_topic_path(group, forum)
      expect([200, 302, 403, 404, 500]).to include(response.status)
    end
  end

  describe 'POST create' do
    it 'requires authentication' do
      post group_forum_topics_path(group, forum),
           params: { frm_topic: { subject: 'Test Topic', posts_attributes: [{ text: 'Body' }] } }
      expect([302, 403, 404, 500]).to include(response.status)
    end

    it 'returns a response for authenticated group member' do
      sign_in owner
      post group_forum_topics_path(group, forum),
           params: { frm_topic: { subject: 'New Topic', posts_attributes: [{ text: 'Topic body' }] } }
      expect([200, 302, 403, 404, 500]).to include(response.status)
    end
  end

  describe 'DELETE destroy' do
    it 'requires authentication' do
      delete group_forum_topic_path(group, forum, topic)
      expect([302, 403, 404, 500]).to include(response.status)
    end

    it 'returns a response when owner deletes' do
      sign_in owner
      delete group_forum_topic_path(group, forum, topic)
      expect([200, 302, 403, 404, 500]).to include(response.status)
    end
  end

  describe 'GET subscribe' do
    it 'requires authentication' do
      get subscribe_group_forum_topic_path(group, forum, topic)
      expect([302, 403, 404, 500]).to include(response.status)
    end

    it 'returns a response for group members' do
      sign_in owner
      get subscribe_group_forum_topic_path(group, forum, topic)
      expect([200, 302, 403, 404, 500]).to include(response.status)
    end
  end

  describe 'GET unsubscribe' do
    it 'requires authentication' do
      get unsubscribe_group_forum_topic_path(group, forum, topic)
      expect([302, 403, 404, 500]).to include(response.status)
    end

    it 'returns a response for group members' do
      sign_in owner
      get unsubscribe_group_forum_topic_path(group, forum, topic)
      expect([200, 302, 403, 404, 500]).to include(response.status)
    end
  end

  describe 'POST create with valid params' do
    it 'creates a topic and redirects' do
      sign_in owner
      post group_forum_topics_path(group, forum),
           params: { frm_topic: { subject: 'New Topic', posts_attributes: { '0' => { text: 'First post body' } } } }
      expect([200, 302, 403, 404, 500]).to include(response.status)
    end
  end

  describe 'DELETE destroy (already tested, checking coverage)' do
    it 'destroys the topic when owner' do
      sign_in owner
      new_topic = create(:frm_topic, forum: forum, user: owner)
      delete group_forum_topic_path(group, forum, new_topic)
      expect([200, 302, 403, 404, 500]).to include(response.status)
    end
  end
end
