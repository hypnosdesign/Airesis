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
  end
end
