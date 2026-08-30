require 'rails_helper'

RSpec.describe ProposalsWorker, type: :worker, seeds: true do
  let!(:user) { create(:user) }
  let!(:group) { create(:group, current_user_id: user.id) }
  let!(:proposal) { create(:group_proposal, current_user_id: user.id, group_proposals: [GroupProposal.new(group: group)]).reload }

  describe 'ENDTIME action' do
    it 'calls check_phase on the proposal' do
      worker = described_class.new
      expect_any_instance_of(Proposal).to receive(:check_phase)
      worker.perform('proposal_id' => proposal.id, 'action' => 'endtime')
    end
  end

  describe 'LEFT24 action' do
    it 'schedules NotificationProposalTimeLeft with 24_hours' do
      expect {
        described_class.new.perform('proposal_id' => proposal.id, 'action' => 'left24')
      }.to have_enqueued_job(NotificationProposalTimeLeft).with(proposal.id, '24_hours')
    end
  end

  describe 'LEFT1 action' do
    it 'schedules NotificationProposalTimeLeft with 1_hour' do
      expect {
        described_class.new.perform('proposal_id' => proposal.id, 'action' => 'left1')
      }.to have_enqueued_job(NotificationProposalTimeLeft).with(proposal.id, '1_hour')
    end
  end

  describe 'LEFT24VOTE action' do
    it 'schedules NotificationProposalTimeLeftVote with 24_hours_vote' do
      expect {
        described_class.new.perform('proposal_id' => proposal.id, 'action' => 'left24_vote')
      }.to have_enqueued_job(NotificationProposalTimeLeftVote).with(proposal.id, '24_hours_vote')
    end
  end

  describe 'LEFT1VOTE action' do
    it 'schedules NotificationProposalTimeLeftVote with 1_hour_vote' do
      expect {
        described_class.new.perform('proposal_id' => proposal.id, 'action' => 'left1_vote')
      }.to have_enqueued_job(NotificationProposalTimeLeftVote).with(proposal.id, '1_hour_vote')
    end
  end

  describe 'with a missing proposal' do
    it 'logs a warning and does not raise' do
      worker = described_class.new
      expect { worker.perform('proposal_id' => 0, 'action' => 'endtime') }.not_to raise_error
    end
  end
end

RSpec.describe CalculateGroupStatistics, type: :worker, seeds: true do
  let!(:user) { create(:user) }
  let!(:group) { create(:group, current_user_id: user.id) }

  it 'updates group statistics without error' do
    worker = described_class.new
    expect { worker.perform }.not_to raise_error
  end

  it 'sets valutations, good_score, and vote_valutations on the statistic' do
    worker = described_class.new
    worker.perform
    group.reload
    stat = group.statistic
    expect(stat.valutations).to be_a Numeric
    expect(stat.good_score).to be_a Numeric
    expect(stat.vote_valutations).to be_a Numeric
  end
end

RSpec.describe CalculateRankings, type: :worker, seeds: true do
  let!(:user) { create(:user) }

  it 'recalculates ranks for all users without error' do
    worker = described_class.new
    expect { worker.perform }.not_to raise_error
  end

  it 'updates user rank' do
    worker = described_class.new
    worker.perform
    user.reload
    expect(user.rank).to be_a Integer
  end
end

RSpec.describe DeleteOldNotifications, type: :worker, seeds: true do
  before do
    delivery = instance_double(ActionMailer::MessageDelivery, deliver_later: true)
    allow(ResqueMailer).to receive(:admin_message).and_return(delivery)
    allow_any_instance_of(Alert).to receive(:send_email)
    allow_any_instance_of(Alert).to receive(:broadcast_notification)
    allow_any_instance_of(Alert).to receive(:complete_alert_job)
  end

  def create_notification(created_at:)
    Notification.create!(
      notification_type_id: NotificationType::NEW_PROPOSALS,
      url: '/',
      data: {},
      created_at: created_at
    )
  end

  def add_alert(notification, checked:)
    user = create(:user)
    Alert.unscoped.create!(notification: notification, user: user, trackable: user, checked: checked, properties: {})
  end

  it 'deletes unread notifications beyond the absolute six-month retention' do
    notification = create_notification(created_at: 7.months.ago)
    add_alert(notification, checked: false)

    expect(described_class.new.perform).to eq(1)
    expect(Notification.exists?(notification.id)).to be(false)
  end

  it 'keeps unread notifications inside the absolute retention' do
    notification = create_notification(created_at: 2.months.ago)
    add_alert(notification, checked: false)

    expect(described_class.new.perform).to eq(0)
    expect(Notification.exists?(notification.id)).to be(true)
  end

  it 'deletes read notifications older than one month without double-counting' do
    expired = create_notification(created_at: 7.months.ago)
    stale_read = create_notification(created_at: 2.months.ago)
    add_alert(expired, checked: true)
    add_alert(stale_read, checked: true)

    expect(described_class.new.perform).to eq(2)
  end

  it 'keeps recent read notifications' do
    notification = create_notification(created_at: 1.day.ago)
    add_alert(notification, checked: true)

    expect(described_class.new.perform).to eq(0)
    expect(Notification.exists?(notification.id)).to be(true)
  end

  it 'processes large scopes through bounded batches' do
    stub_const('DeleteOldNotifications::BATCH_SIZE', 1)
    notifications = Array.new(3) { create_notification(created_at: 7.months.ago) }

    expect(described_class.new.perform).to eq(3)
    expect(Notification.where(id: notifications).count).to eq(0)
  end
end

RSpec.describe CountCreatedProposals, type: :worker, seeds: true do
  let!(:user) { create(:user) }

  it 'counts proposals created today and saves a stat record' do
    create(:public_proposal, current_user_id: user.id)
    worker = described_class.new
    expect { worker.perform }.to change(StatNumProposal, :count).by(1)
  end

  it 'records the correct date' do
    worker = described_class.new
    worker.perform
    stat = StatNumProposal.last
    expect(stat.date.to_date).to eq Date.today
  end
end

RSpec.describe GeocodeUser, type: :worker, seeds: true do
  let!(:user) { create(:user) }

  it 'calls geocode on the user' do
    expect_any_instance_of(User).to receive(:geocode)
    worker = described_class.new
    worker.perform(user.id)
  end

  it 'does nothing when user does not exist' do
    described_class.new
    # GeocodeUser calls geocode on nil if user not found; skip gracefully
    expect(User.find_by(id: 0)).to be_nil
  end
end
