require 'rails_helper'
require 'requests_helper'

RSpec.describe Frm::Admin::CategoriesController, seeds: true do
  let!(:owner) { create(:user) }
  let!(:group) { create(:group, current_user_id: owner.id) }
  let!(:category) { create(:frm_category, group: group) }
  let(:turbo_stream_headers) { { 'ACCEPT' => 'text/vnd.turbo-stream.html' } }

  describe 'GET index' do
    it 'redirects to sign in when not authenticated' do
      get group_frm_admin_categories_path(group)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group owner' do
      sign_in owner
      get group_frm_admin_categories_path(group)
      expect(response).to have_http_status(:ok)
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
      expect(response).to have_http_status(:ok)
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
      expect(response).to redirect_to(group_frm_admin_categories_url(group))
      expect(response).to have_http_status(:see_other)
    end
  end

  describe 'PATCH update' do
    it 'redirects to sign in when not authenticated' do
      patch group_frm_admin_category_path(group, category),
            params: { frm_category: { name: 'Updated', visible_outside: false } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group owner (HTML)' do
      sign_in owner
      patch group_frm_admin_category_path(group, category),
            params: { frm_category: { name: 'Updated Category', visible_outside: false } }
      expect(response).to redirect_to(group_frm_admin_categories_url(group))
      expect(response).to have_http_status(:see_other)
    end

    it 'returns a Turbo Stream response for group owner' do
      sign_in owner
      patch group_frm_admin_category_path(group, category),
            headers: turbo_stream_headers,
            params: { frm_category: { name: 'JS Updated', visible_outside: true } }
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
    end

    it 'handles invalid update (empty name)' do
      sign_in owner
      patch group_frm_admin_category_path(group, category),
            params: { frm_category: { name: '' } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'returns 422 for an invalid Turbo Stream update' do
      sign_in owner

      patch group_frm_admin_category_path(group, category),
            headers: turbo_stream_headers,
            params: { frm_category: { name: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
    end
  end

  describe 'POST create with Turbo Stream format' do
    it 'returns a Turbo Stream response on success' do
      sign_in owner
      post group_frm_admin_categories_path(group),
           headers: turbo_stream_headers,
           params: { frm_category: { name: 'JS Category', visible_outside: true } }
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
    end

    it 'returns a response on failure (missing name)' do
      sign_in owner
      post group_frm_admin_categories_path(group),
           params: { frm_category: { name: '' } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'DELETE destroy with Turbo Stream format' do
    it 'returns a Turbo Stream response for group owner' do
      sign_in owner
      delete group_frm_admin_category_path(group, category), headers: turbo_stream_headers
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
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
      expect(response).to redirect_to(group_frm_admin_categories_url(group))
      expect(response).to have_http_status(:see_other)
    end
  end
end
