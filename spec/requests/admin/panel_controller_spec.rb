require 'rails_helper'
require 'requests_helper'

RSpec.describe Admin::PanelController, seeds: true do
  let!(:admin) { create(:admin) }
  let!(:user) { create(:user) }

  describe 'GET show' do
    it 'is not routed for guests or regular users' do
      get admin_panel_path
      expect(response).to have_http_status(:not_found)

      sign_in user
      get admin_panel_path
      expect(response).to have_http_status(:not_found)
    end

    it 'renders the operations panel for an administrator' do
      sign_in admin

      get admin_panel_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t('admin_ui.panel.title'))
    end
  end

  describe 'POST maintenance operations' do
    before { sign_in admin }

    it 'recalculates rankings and redirects with 303' do
      allow(AdminHelper).to receive(:calculate_ranking)

      post calculate_rankings_admin_panel_path

      expect(AdminHelper).to have_received(:calculate_ranking)
      expect(response).to redirect_to(admin_panel_path)
      expect(response).to have_http_status(:see_other)
    end

    it 'reconciles proposal states and redirects with 303' do
      allow(Proposal).to receive_messages(invalid_debate_phase: [], invalid_waiting_phase: [], invalid_vote_phase: [])

      post change_proposals_state_admin_panel_path

      expect(response).to redirect_to(admin_panel_path)
      expect(response).to have_http_status(:see_other)
    end

    it 'queues notification cleanup and redirects with 303' do
      expect do
        post delete_old_notifications_admin_panel_path
      end.to have_enqueued_job(DeleteOldNotifications)

      expect(flash[:notice]).to eq(I18n.t('admin_ui.panel.notifications_cleanup_queued'))
      expect(response).to have_http_status(:see_other)
    end

    it 'refreshes the sitemap and reenables the task' do
      task = instance_double(Rake::Task, invoke: true, reenable: true)
      allow(Rake::Task).to receive(:task_defined?).with('sitemap:refresh').and_return(true)
      allow(Rake::Task).to receive(:[]).with('sitemap:refresh').and_return(task)

      post write_sitemap_admin_panel_path

      expect(task).to have_received(:invoke)
      expect(task).to have_received(:reenable)
      expect(response).to have_http_status(:see_other)
    end

    it 'does not expose maintenance operations through GET' do
      get calculate_rankings_admin_panel_path

      expect(response).to have_http_status(:not_found)
    end
  end
end
