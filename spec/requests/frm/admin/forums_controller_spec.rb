require 'rails_helper'
require 'requests_helper'

RSpec.describe Frm::Admin::ForumsController, seeds: true do
  let!(:owner) { create(:user) }
  let!(:group) { create(:group, current_user_id: owner.id) }
  let!(:category) { create(:frm_category, group: group) }
  let!(:forum) { create(:frm_forum, category: category, group: group) }

  describe 'GET index' do
    it 'redirects to sign in when not authenticated' do
      get group_frm_admin_forums_path(group)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group owner' do
      sign_in owner
      get group_frm_admin_forums_path(group)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET new' do
    it 'redirects to sign in when not authenticated' do
      get new_group_frm_admin_forum_path(group)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group owner' do
      sign_in owner
      get new_group_frm_admin_forum_path(group)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST create' do
    it 'redirects to sign in when not authenticated' do
      post group_frm_admin_forums_path(group),
           params: { frm_forum: { name: 'New Forum', description: 'desc', category_id: category.id } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group owner' do
      sign_in owner
      post group_frm_admin_forums_path(group),
           params: { frm_forum: { name: 'New Forum', description: 'desc', category_id: category.id } }
      expect(response).to redirect_to(group_frm_admin_forums_url(group))
      expect(response).to have_http_status(:see_other)
    end

    it 'cannot assign a category from another group' do
      other_category = create(:frm_category)
      sign_in owner

      expect do
        post group_frm_admin_forums_path(group),
             params: { frm_forum: { name: 'Cross group', description: 'desc', category_id: other_category.id } }
      end.not_to change(Frm::Forum, :count)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PATCH update' do
    it 'cannot assign a moderator team from another group' do
      other_group = create(:group)
      other_mod = Frm::Mod.create!(name: 'Other moderators', group: other_group)
      sign_in owner

      patch group_frm_admin_forum_path(group, forum), params: { frm_forum: { mod_ids: [other_mod.id] } }

      expect(response).to have_http_status(:not_found)
      expect(forum.reload.mods).to be_empty
    end
  end

  describe 'DELETE destroy' do
    it 'redirects to sign in when not authenticated' do
      delete group_frm_admin_forum_path(group, forum)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group owner' do
      sign_in owner
      delete group_frm_admin_forum_path(group, forum)
      expect(response).to redirect_to(group_frm_admin_forums_url(group))
      expect(response).to have_http_status(:see_other)
    end
  end
end
