require 'rails_helper'
require 'requests_helper'

RSpec.describe Frm::ModerationController, seeds: true do
  let!(:owner) { create(:user) }
  let!(:group) { create(:group, current_user_id: owner.id) }
  let!(:forum) do
    create(:frm_forum, category: create(:frm_category, group: group, visible_outside: true), group: group, visible_outside: true)
  end
  let!(:topic) { create(:approved_topic, forum: forum, user: owner) }
  let!(:post_record) { create(:post, topic: topic, user: owner).tap { |post| post.update!(state: 'pending_review') } }

  describe 'GET index' do
    it 'redirects unauthenticated users to sign in' do
      get group_frm_forum_moderator_tools_path(group, forum)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'renders the queue for the group administrator' do
      sign_in owner

      get group_frm_forum_moderator_tools_path(group, forum)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(topic.subject)
    end
  end

  describe 'PUT moderate posts' do
    it 'approves a pending post in the current forum' do
      sign_in owner

      put group_frm_forum_moderate_posts_path(group, forum),
          params: { posts: { post_record.id => { moderation_option: 'approve' } } }

      expect(post_record.reload.state).to eq('approved')
      expect(response).to redirect_to(group_frm_forum_moderator_tools_path(group, forum))
      expect(response).to have_http_status(:see_other)
    end

    it 'rejects destructive method names and keeps the post' do
      sign_in owner

      expect do
        put group_frm_forum_moderate_posts_path(group, forum),
            params: { posts: { post_record.id => { moderation_option: 'destroy' } } }
      end.not_to change(Frm::Post, :count)

      expect(post_record.reload.state).to eq('pending_review')
      expect(response).to have_http_status(:see_other)
    end

    it 'ignores non-numeric post keys and unapproved attributes' do
      sign_in owner

      put group_frm_forum_moderate_posts_path(group, forum),
          params: {
            posts: {
              'not-a-post-id' => { moderation_option: 'approve' },
              post_record.id => { moderation_option: '', admin: true }
            }
          }

      expect(post_record.reload.state).to eq('pending_review')
      expect(response).to have_http_status(:see_other)
    end

    it 'cannot moderate a post that belongs to another forum' do
      other_owner = create(:user)
      other_group = create(:group, current_user_id: other_owner.id)
      other_category = create(:frm_category, group: other_group, visible_outside: true)
      other_forum = create(:frm_forum, category: other_category, group: other_group, visible_outside: true)
      other_topic = create(:approved_topic, forum: other_forum, user: other_owner)
      other_post = create(:post, topic: other_topic, user: other_owner)
      other_post.update!(state: 'pending_review')
      sign_in owner

      put group_frm_forum_moderate_posts_path(group, forum),
          params: { posts: { other_post.id => { moderation_option: 'approve' } } }

      expect(other_post.reload.state).to eq('pending_review')
      expect(response).to have_http_status(:see_other)
    end

    it 'rolls back earlier decisions when a later item is invalid' do
      second_post = create(:post, topic: topic, user: owner)
      second_post.update!(state: 'pending_review')
      sign_in owner

      put group_frm_forum_moderate_posts_path(group, forum),
          params: {
            posts: {
              post_record.id => { moderation_option: 'approve' },
              second_post.id => { moderation_option: 'destroy' }
            }
          }

      expect(post_record.reload.state).to eq('pending_review')
      expect(second_post.reload.state).to eq('pending_review')
    end
  end

  describe 'PUT moderate topic' do
    it 'approves a scoped pending topic' do
      topic.update!(state: 'pending_review')
      sign_in owner

      put group_frm_moderate_forum_topic_path(group, forum, topic),
          params: { frm_topic: { moderation_option: 'approve' } }

      expect(topic.reload.state).to eq('approved')
      expect(response).to redirect_to(group_forum_topic_path(group, forum, topic))
      expect(response).to have_http_status(:see_other)
    end

    it 'rejects unknown topic moderation operations' do
      topic.update!(state: 'pending_review')
      sign_in owner

      put group_frm_moderate_forum_topic_path(group, forum, topic),
          params: { frm_topic: { moderation_option: 'destroy' } }

      expect(topic.reload.state).to eq('pending_review')
      expect(response).to have_http_status(:see_other)
    end
  end
end
