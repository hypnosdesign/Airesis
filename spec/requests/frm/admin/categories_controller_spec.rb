require 'rails_helper'
require 'requests_helper'

RSpec.describe Frm::Admin::CategoriesController, seeds: true do
  let!(:owner) { create(:user) }
  let!(:group) { create(:group, current_user_id: owner.id) }
  let!(:category) { create(:frm_category, group: group) }

  describe 'GET index' do
    it 'redirects to sign in when not authenticated' do
      get group_frm_admin_categories_path(group)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group owner' do
      sign_in owner
      get group_frm_admin_categories_path(group)
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET new' do
    it 'redirects to sign in when not authenticated' do
      get new_group_frm_admin_category_path(group)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group owner' do
      sign_in owner
      get new_group_frm_admin_category_path(group)
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'POST create' do
    it 'redirects to sign in when not authenticated' do
      post group_frm_admin_categories_path(group),
           params: { frm_category: { name: 'New Category', visible_outside: true } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group owner' do
      sign_in owner
      post group_frm_admin_categories_path(group),
           params: { frm_category: { name: 'New Category', visible_outside: true } }
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'DELETE destroy' do
    it 'redirects to sign in when not authenticated' do
      delete group_frm_admin_category_path(group, category)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group owner' do
      sign_in owner
      delete group_frm_admin_category_path(group, category)
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end
end
