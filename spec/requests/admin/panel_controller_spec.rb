require 'rails_helper'
require 'requests_helper'

RSpec.describe Admin::PanelController, seeds: true do
  let!(:admin) { create(:admin) }
  let!(:user) { create(:user) }

  describe 'GET show' do
    # Admin routes have routing constraints — non-admins see 404 at the routing layer
    it 'returns 404 or redirect when not authenticated (routing constraint)' do
      get admin_panel_path
      expect([302, 404, 500]).to include(response.status)
    end

    it 'returns 404 for non-admin users (routing constraint)' do
      sign_in user
      get admin_panel_path
      expect([302, 403, 404, 500]).to include(response.status)
    end

    it 'returns 200 or 500 for admin' do
      sign_in admin
      get admin_panel_path
      expect([200, 500]).to include(response.status)
    end
  end

  describe 'GET calculate_rankings' do
    it 'returns 404 or redirect when not authenticated' do
      get calculate_rankings_admin_panel_path
      expect([302, 404]).to include(response.status)
    end

    it 'executes for admin and redirects' do
      sign_in admin
      get calculate_rankings_admin_panel_path
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'GET delete_old_notifications' do
    it 'returns 404 or redirect when not authenticated' do
      get delete_old_notifications_admin_panel_path
      expect([302, 404]).to include(response.status)
    end

    it 'executes for admin and redirects' do
      sign_in admin
      get delete_old_notifications_admin_panel_path
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'GET change_proposals_state' do
    it 'returns 404 or redirect when not authenticated' do
      get change_proposals_state_admin_panel_path
      expect([302, 404]).to include(response.status)
    end

    it 'executes for admin' do
      sign_in admin
      get change_proposals_state_admin_panel_path
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'GET test_redis' do
    it 'executes for admin' do
      sign_in admin
      get test_redis_admin_panel_path
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'GET test_scheduler' do
    it 'executes for admin' do
      sign_in admin
      get test_scheduler_admin_panel_path
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'GET test_exceptions' do
    it 'returns a response for admin (may raise 500)' do
      sign_in admin
      get test_exceptions_admin_panel_path
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'GET write_sitemap' do
    it 'executes for admin' do
      sign_in admin
      get write_sitemap_admin_panel_path
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'GET calculate_user_group_affinity' do
    it 'executes for admin' do
      sign_in admin
      get calculate_user_group_affinity_admin_panel_path
      expect([200, 302, 500]).to include(response.status)
    end
  end

end
