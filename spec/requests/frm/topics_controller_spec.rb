require 'rails_helper'
require 'requests_helper'

RSpec.describe Frm::TopicsController, seeds: true do
  let!(:owner) { create(:user) }
  let!(:group) { create(:group, current_user_id: owner.id) }
  let!(:forum) do
    create(:frm_forum, category: create(:frm_category, group: group, visible_outside: true), group: group, visible_outside: true)
  end
  let!(:topic) { create(:approved_topic, forum: forum, user: owner) }

  describe 'GET show' do
    it 'renders the topic for a group member' do
      sign_in owner

      get group_forum_topic_path(group, forum, topic)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(topic.subject)
    end
  end

  describe 'GET new' do
    it 'redirects unauthenticated users to sign in' do
      get new_group_forum_topic_path(group, forum)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'renders the form for a group member' do
      sign_in owner

      get new_group_forum_topic_path(group, forum)

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST create' do
    it 'creates a topic and redirects with 303' do
      sign_in owner

      expect do
        post group_forum_topics_path(group, forum),
             params: { frm_topic: { subject: 'A focused civic question', posts_attributes: { '0' => { text: 'First post body' } } } }
      end.to change(Frm::Topic, :count).by(1)

      created_topic = Frm::Topic.order(:id).last
      expect(response).to redirect_to(group_forum_topic_url(group, forum, created_topic))
      expect(response).to have_http_status(:see_other)
    end

    it 'returns 422 and preserves errors for invalid input' do
      sign_in owner

      expect do
        post group_forum_topics_path(group, forum),
             params: { frm_topic: { subject: '', posts_attributes: { '0' => { text: '' } } } }
      end.not_to change(Frm::Topic, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'DELETE destroy' do
    it 'destroys an owned topic and redirects with 303' do
      sign_in owner

      expect do
        delete group_forum_topic_path(group, forum, topic)
      end.to change(Frm::Topic, :count).by(-1)

      expect(response).to redirect_to(group_forum_url(group, forum))
      expect(response).to have_http_status(:see_other)
    end
  end

  describe 'subscriptions' do
    let!(:other_topic) { create(:approved_topic, forum: forum, user: create(:user)) }

    it 'subscribes only through POST' do
      sign_in owner

      expect do
        post subscribe_group_forum_topic_path(group, forum, other_topic)
      end.to(change { other_topic.subscriptions.where(subscriber_id: owner.id).count }.by(1))

      expect(response).to have_http_status(:see_other)
    end

    it 'renders a safe GET confirmation without mutating the subscription' do
      other_topic.subscribe_user(owner.id)
      sign_in owner

      expect do
        get unsubscribe_group_forum_topic_path(group, forum, other_topic)
      end.not_to(change { other_topic.subscriptions.where(subscriber_id: owner.id).count })

      expect(response).to have_http_status(:ok)
    end

    it 'unsubscribes through DELETE and redirects with 303' do
      other_topic.subscribe_user(owner.id)
      sign_in owner

      expect do
        delete unsubscribe_group_forum_topic_path(group, forum, other_topic)
      end.to(change { other_topic.subscriptions.where(subscriber_id: owner.id).count }.by(-1))

      expect(response).to have_http_status(:see_other)
    end
  end
end
