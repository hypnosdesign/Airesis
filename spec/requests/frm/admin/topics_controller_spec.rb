require 'rails_helper'
require 'requests_helper'

RSpec.describe Frm::Admin::TopicsController, seeds: true do
  let!(:owner) { create(:user) }
  let!(:group) { create(:group, current_user_id: owner.id) }
  let!(:category) { create(:frm_category, group: group) }
  let!(:forum) { create(:frm_forum, category: category, group: group) }
  let!(:topic) { create(:approved_topic, forum: forum) }

  describe 'PUT toggle_hide' do
    it 'redirects to sign in when not authenticated' do
      put toggle_hide_group_frm_admin_forum_topic_path(group, forum, topic)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group owner' do
      sign_in owner
      put toggle_hide_group_frm_admin_forum_topic_path(group, forum, topic)
      expect(response).to have_http_status(:see_other)
      expect(topic.reload.hidden).to be(true)
    end
  end

  describe 'PATCH update' do
    it 'cannot move a topic to a forum from another group' do
      other_group = create(:group)
      other_forum = create(:frm_forum, category: create(:frm_category, group: other_group), group: other_group)
      sign_in owner

      patch group_frm_admin_forum_topic_path(group, forum, topic),
            params: { frm_topic: { subject: topic.subject, forum_id: other_forum.id } }

      expect(response).to have_http_status(:not_found)
      expect(topic.reload.forum).to eq(forum)
    end
  end

  describe 'PUT toggle_lock' do
    it 'redirects to sign in when not authenticated' do
      put toggle_lock_group_frm_admin_forum_topic_path(group, forum, topic)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group owner' do
      sign_in owner
      put toggle_lock_group_frm_admin_forum_topic_path(group, forum, topic)
      expect(response).to have_http_status(:see_other)
      expect(topic.reload.locked).to be(true)
    end
  end

  describe 'PUT toggle_pin' do
    it 'redirects to sign in when not authenticated' do
      put toggle_pin_group_frm_admin_forum_topic_path(group, forum, topic)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group owner' do
      sign_in owner
      put toggle_pin_group_frm_admin_forum_topic_path(group, forum, topic)
      expect(response).to have_http_status(:see_other)
      expect(topic.reload.pinned).to be(true)
    end
  end

  describe 'DELETE destroy' do
    it 'redirects to sign in when not authenticated' do
      delete group_frm_admin_forum_topic_path(group, forum, topic)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group owner' do
      sign_in owner
      delete group_frm_admin_forum_topic_path(group, forum, topic)
      expect(response).to have_http_status(:see_other)
      expect(Frm::Topic.exists?(topic.id)).to be(false)
    end
  end
end
