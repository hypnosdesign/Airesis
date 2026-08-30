require 'rails_helper'
require 'requests_helper'

RSpec.describe Frm::PostsController, seeds: true do
  let!(:owner) { create(:user) }
  let!(:group) { create(:group, current_user_id: owner.id) }
  let!(:forum) do
    create(:frm_forum, category: create(:frm_category, group: group, visible_outside: true), group: group, visible_outside: true)
  end
  let!(:topic) { create(:approved_topic, forum: forum, user: owner) }
  let!(:post_record) { topic.posts.first }

  describe 'GET new' do
    it 'redirects unauthenticated users to sign in' do
      get new_group_forum_topic_post_path(group, forum, topic)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'renders a reply form for an authorized user' do
      sign_in owner

      get new_group_forum_topic_post_path(group, forum, topic, reply_to_id: post_record.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(topic.subject)
    end

    it 'redirects with 303 when a quoted post no longer exists' do
      sign_in owner

      get new_group_forum_topic_post_path(group, forum, topic, quote: true, reply_to_id: 0)

      expect(response).to redirect_to(group_forum_topic_url(group, forum, topic))
      expect(response).to have_http_status(:see_other)
    end
  end

  describe 'POST create' do
    it 'creates a reply and redirects with 303' do
      sign_in owner

      expect do
        post group_forum_topic_posts_path(group, forum, topic), params: { frm_post: { text: 'A useful reply' } }
      end.to(change { topic.posts.count }.by(1))

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(group_forum_topic_url(group, forum, topic, page: topic.reload.last_page))
    end

    it 'returns 422 for blank content' do
      sign_in owner

      expect do
        post group_forum_topic_posts_path(group, forum, topic), params: { frm_post: { text: '' } }
      end.not_to(change { topic.posts.count })

      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'does not create a reply on a locked topic' do
      topic.update!(locked: true)
      sign_in owner

      expect do
        post group_forum_topic_posts_path(group, forum, topic), params: { frm_post: { text: 'Blocked reply' } }
      end.not_to(change { topic.posts.count })

      expect(response).to redirect_to(group_forum_topic_url(group, forum, topic))
      expect(response).to have_http_status(:see_other)
    end

    it 'cannot link a reply to a post from another topic' do
      other_topic = create(:approved_topic, forum: forum, user: owner)
      sign_in owner

      expect do
        post group_forum_topic_posts_path(group, forum, topic),
             params: { frm_post: { text: 'Cross-topic reply', reply_to_id: other_topic.posts.first.id } }
      end.not_to(change { topic.posts.count })

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PATCH update' do
    it 'updates an owned post and redirects with 303' do
      sign_in owner

      patch group_forum_topic_post_path(group, forum, topic, post_record),
            params: { frm_post: { text: 'Updated contribution' } }

      expect(response).to redirect_to(group_forum_topic_url(group, forum, topic))
      expect(response).to have_http_status(:see_other)
      expect(post_record.reload.text.to_plain_text).to include('Updated contribution')
    end

    it 'returns 422 for invalid content' do
      sign_in owner

      patch group_forum_topic_post_path(group, forum, topic, post_record), params: { frm_post: { text: '' } }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'cannot move a reply relationship to another topic' do
      other_topic = create(:approved_topic, forum: forum, user: owner)
      sign_in owner

      patch group_forum_topic_post_path(group, forum, topic, post_record),
            params: { frm_post: { text: 'Cross-topic edit', reply_to_id: other_topic.posts.first.id } }

      expect(response).to have_http_status(:not_found)
      expect(post_record.reload.reply_to).to be_nil
    end
  end

  describe 'DELETE destroy' do
    it 'destroys a post and redirects with 303' do
      extra_post = create(:post, topic: topic, user: owner)
      sign_in owner

      expect do
        delete group_forum_topic_post_path(group, forum, topic, extra_post)
      end.to(change { topic.posts.count }.by(-1))

      expect(response).to redirect_to(group_forum_topic_path(group, forum, topic))
      expect(response).to have_http_status(:see_other)
    end

    it 'destroys the topic when its final post is deleted' do
      sign_in owner

      expect do
        delete group_forum_topic_post_path(group, forum, topic, post_record)
      end.to change(Frm::Topic, :count).by(-1)

      expect(response).to redirect_to(group_forum_path(group, forum))
      expect(response).to have_http_status(:see_other)
    end
  end
end
