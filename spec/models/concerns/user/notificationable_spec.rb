require 'rails_helper'
require 'requests_helper'

RSpec.describe User::Notificationable, seeds: true do
  let!(:user) { create(:user) }

  describe 'associations' do
    it 'has alerts' do
      expect(user.alerts).to respond_to(:each)
    end

    it 'has unread_alerts' do
      expect(user.unread_alerts).to respond_to(:each)
    end

    it 'has blocked_alerts' do
      expect(user.blocked_alerts).to respond_to(:each)
    end

    it 'has blocked_emails' do
      expect(user.blocked_emails).to respond_to(:each)
    end

    it 'has blocked_notifications' do
      expect(user.blocked_notifications).to respond_to(:each)
    end

    it 'has blocked_email_notifications' do
      expect(user.blocked_email_notifications).to respond_to(:each)
    end
  end

  describe '#init_notifications' do
    it 'builds default blocked alerts' do
      user.init_notifications
      expect(user.blocked_alerts.size).to be >= 3
    end
  end
end
