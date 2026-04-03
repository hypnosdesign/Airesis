require 'rails_helper'

RSpec.describe AlertJob, type: :model, seeds: true do
  let!(:user) { create(:user) }
  let!(:proposal) { create(:public_proposal, current_user_id: user.id) }
  let!(:notification_type) { NotificationType.first }

  let(:alert_job) do
    AlertJob.create!(
      trackable: proposal,
      notification_type: notification_type,
      user: user,
      jid: SecureRandom.hex(12),
      status: 0
    )
  end

  describe '#scheduled?' do
    it 'returns true when status is 0' do
      expect(alert_job.scheduled?).to be true
    end

    it 'returns false when status is not 0' do
      alert_job.update(status: 2)
      expect(alert_job.scheduled?).to be false
    end
  end

  describe '#canceled?' do
    it 'returns false when not canceled' do
      expect(alert_job.canceled?).to be false
    end

    it 'returns true after canceled!' do
      alert_job.canceled!
      expect(alert_job.canceled?).to be true
    end
  end

  describe '#completed?' do
    it 'returns false when not completed' do
      expect(alert_job.completed?).to be false
    end

    it 'returns true when status is 2' do
      alert_job.update(status: 2)
      expect(alert_job.completed?).to be true
    end
  end

  describe '#canceled!' do
    it 'updates status to 3' do
      alert_job.canceled!
      expect(alert_job.reload.status).to eq 3
    end
  end

  describe 'validations' do
    it 'requires trackable' do
      job = AlertJob.new(notification_type: notification_type, user: user, jid: 'test123')
      expect(job).not_to be_valid
      expect(job.errors[:trackable]).to be_present
    end

    it 'requires notification_type' do
      job = AlertJob.new(trackable: proposal, user: user, jid: 'test456')
      expect(job).not_to be_valid
      expect(job.errors[:notification_type]).to be_present
    end

    it 'requires unique jid' do
      alert_job
      job2 = AlertJob.new(trackable: proposal, notification_type: notification_type,
                          user: user, jid: alert_job.jid)
      expect(job2).not_to be_valid
    end
  end

  describe '.delay_for' do
    it 'returns a duration based on notification type alert_delay' do
      notification = Notification.new(notification_type: notification_type)
      result = AlertJob.delay_for(notification)
      expect(result).to be_a(ActiveSupport::Duration)
    end
  end
end
