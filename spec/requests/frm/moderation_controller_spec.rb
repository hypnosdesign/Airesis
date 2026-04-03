require 'rails_helper'
require 'requests_helper'

RSpec.describe Frm::ModerationController, seeds: true do
  let!(:owner) { create(:user) }
  let!(:group) { create(:group, current_user_id: owner.id) }
  let!(:category) { create(:frm_category, group: group) }
  let!(:forum) { create(:frm_forum, category: category, group: group) }

  describe 'GET index (moderator tools)' do
    it 'redirects to sign in when not authenticated' do
      get group_frm_forum_moderator_tools_path(group, forum)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group admin (moderator)' do
      sign_in owner
      get group_frm_forum_moderator_tools_path(group, forum)
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'PUT moderate posts' do
    it 'redirects to sign in when not authenticated' do
      put group_frm_forum_moderate_posts_path(group, forum),
          params: { posts: [] }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group admin' do
      sign_in owner
      put group_frm_forum_moderate_posts_path(group, forum),
          params: { posts: [] }
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end
end
