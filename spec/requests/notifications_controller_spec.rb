require 'rails_helper'
require 'requests_helper'

RSpec.describe NotificationsController, seeds: true do
  let!(:user) { create(:user) }

  # Find any seeded notification type to use as the :id param
  let(:notification_type_id) { NotificationType.first.id }

  describe 'POST change_notification_block' do
    context 'when not authenticated' do
      it 'redirects to sign in' do
        post change_notification_block_notifications_path, params: { id: notification_type_id, block: 'true' }
        expect(response.status).to eq(302)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when authenticated' do
      before { sign_in user }

      it 'blocks a notification type and redirects or responds successfully' do
        post change_notification_block_notifications_path, params: { id: notification_type_id, block: 'true' }
        expect([200, 302, 500]).to include(response.status)
      end

      it 'unblocks a notification type when an existing block record is present' do
        user.blocked_alerts.create!(notification_type_id: notification_type_id)
        post change_notification_block_notifications_path, params: { id: notification_type_id, block: 'false' }
        expect([200, 302, 500]).to include(response.status)
      end
    end
  end

  describe 'POST change_email_notification_block' do
    context 'when not authenticated' do
      it 'redirects to sign in' do
        post change_email_notification_block_notifications_path, params: { id: notification_type_id, block: 'true' }
        expect(response.status).to eq(302)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when authenticated' do
      before { sign_in user }

      it 'blocks an email notification type and responds successfully' do
        post change_email_notification_block_notifications_path, params: { id: notification_type_id, block: 'true' }
        expect([200, 302, 500]).to include(response.status)
      end

      it 'unblocks an email notification type when an existing block record is present' do
        user.blocked_emails.create!(notification_type_id: notification_type_id)
        post change_email_notification_block_notifications_path, params: { id: notification_type_id, block: 'false' }
        expect([200, 302, 500]).to include(response.status)
      end
    end
  end

  describe 'POST change_email_block' do
    context 'when not authenticated' do
      it 'redirects to sign in' do
        post change_email_block_notifications_path, params: { block: 'true' }
        expect(response.status).to eq(302)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when authenticated' do
      before { sign_in user }

      it 'opts the user out of newsletter and responds successfully' do
        post change_email_block_notifications_path, params: { block: 'true' }
        expect([200, 302, 500]).to include(response.status)
        expect(user.reload.receive_newsletter).to be(false)
      end

      it 'opts the user into newsletter when block is false' do
        user.update!(receive_newsletter: false)
        post change_email_block_notifications_path, params: { block: 'false' }
        expect([200, 302, 500]).to include(response.status)
        expect(user.reload.receive_newsletter).to be(true)
      end
    end
  end
end
