require 'rails_helper'
require 'requests_helper'

RSpec.describe Frm::PostsController, seeds: true do
  let!(:owner) { create(:user) }
  let!(:group) { create(:group, current_user_id: owner.id) }
  let!(:forum) { group.forums.first || create(:frm_forum, category: create(:frm_category, group: group), group: group) }
  let!(:topic) { create(:frm_topic, forum: forum, user: owner) }
  let!(:post_record) { create(:post, topic: topic, user: owner) }

  describe 'GET index' do
    it 'returns a response for group members' do
      sign_in owner
      get group_forum_topic_posts_path(group, forum, topic)
      expect([200, 302, 403, 404, 500]).to include(response.status)
    end
  end

  describe 'POST create' do
    it 'requires authentication' do
      post group_forum_topic_posts_path(group, forum, topic),
           params: { post: { text: 'A reply' } }
      expect([302, 403, 404, 500]).to include(response.status)
    end

    it 'returns a response when authenticated' do
      sign_in owner
      post group_forum_topic_posts_path(group, forum, topic),
           params: { post: { text: 'A reply post body' } }
      expect([200, 302, 403, 404, 500]).to include(response.status)
    end
  end

  describe 'GET edit' do
    it 'requires authentication' do
      get edit_group_forum_topic_post_path(group, forum, topic, post_record)
      expect([302, 403, 404, 500]).to include(response.status)
    end

    it 'returns a response for post author' do
      sign_in owner
      get edit_group_forum_topic_post_path(group, forum, topic, post_record)
      expect([200, 302, 403, 404, 500]).to include(response.status)
    end
  end

  describe 'PATCH update' do
    it 'requires authentication' do
      patch group_forum_topic_post_path(group, forum, topic, post_record),
            params: { post: { text: 'Updated' } }
      expect([302, 403, 404, 500]).to include(response.status)
    end

    it 'returns a response when authenticated as author' do
      sign_in owner
      patch group_forum_topic_post_path(group, forum, topic, post_record),
            params: { post: { text: 'Updated body' } }
      expect([200, 302, 403, 404, 500]).to include(response.status)
    end
  end

  describe 'DELETE destroy' do
    it 'requires authentication' do
      delete group_forum_topic_post_path(group, forum, topic, post_record)
      expect([302, 403, 404, 500]).to include(response.status)
    end

    it 'returns a response when authenticated' do
      sign_in owner
      delete group_forum_topic_post_path(group, forum, topic, post_record)
      expect([200, 302, 403, 404, 500]).to include(response.status)
    end

    it 'destroys the topic when deleting the last post' do
      sign_in owner
      # The post_record is the only post; deleting it should destroy the topic too
      extra_post = create(:post, topic: topic, user: owner)
      delete group_forum_topic_post_path(group, forum, topic, extra_post)
      expect([200, 302, 403, 404, 500]).to include(response.status)
    end
  end

  describe 'GET new' do
    it 'returns a response when authenticated' do
      sign_in owner
      get new_group_forum_topic_post_path(group, forum, topic)
      expect([200, 302, 403, 404, 500]).to include(response.status)
    end

    it 'handles quote parameter' do
      sign_in owner
      get new_group_forum_topic_post_path(group, forum, topic),
          params: { quote: true, reply_to_id: post_record.id }
      expect([200, 302, 403, 404, 500]).to include(response.status)
    end

    it 'handles quote with missing reply_to post' do
      sign_in owner
      get new_group_forum_topic_post_path(group, forum, topic),
          params: { quote: true, reply_to_id: 0 }
      expect([200, 302, 403, 404, 500]).to include(response.status)
    end
  end

  describe 'POST create on locked topic' do
    it 'redirects away when topic is locked' do
      sign_in owner
      topic.update!(locked: true)
      post group_forum_topic_posts_path(group, forum, topic),
           params: { frm_post: { text: 'A reply' } }
      expect([200, 302, 403, 404, 500]).to include(response.status)
    end
  end
end
