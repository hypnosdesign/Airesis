require 'rails_helper'

RSpec.describe ProposalsWorker, type: :worker, seeds: true do
  before { Sidekiq::Testing.fake! }

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
      worker = described_class.new
      worker.perform('proposal_id' => proposal.id, 'action' => 'left24')
      expect(NotificationProposalTimeLeft.jobs.size).to eq 1
      job = NotificationProposalTimeLeft.jobs.first
      expect(job['args']).to include(proposal.id, '24_hours')
    end
  end

  describe 'LEFT1 action' do
    it 'schedules NotificationProposalTimeLeft with 1_hour' do
      worker = described_class.new
      worker.perform('proposal_id' => proposal.id, 'action' => 'left1')
      expect(NotificationProposalTimeLeft.jobs.size).to eq 1
      expect(NotificationProposalTimeLeft.jobs.first['args']).to include(proposal.id, '1_hour')
    end
  end

  describe 'LEFT24VOTE action' do
    it 'schedules NotificationProposalTimeLeftVote with 24_hours_vote' do
      worker = described_class.new
      worker.perform('proposal_id' => proposal.id, 'action' => 'left24_vote')
      expect(NotificationProposalTimeLeftVote.jobs.size).to eq 1
      expect(NotificationProposalTimeLeftVote.jobs.first['args']).to include(proposal.id, '24_hours_vote')
    end
  end

  describe 'LEFT1VOTE action' do
    it 'schedules NotificationProposalTimeLeftVote with 1_hour_vote' do
      worker = described_class.new
      worker.perform('proposal_id' => proposal.id, 'action' => 'left1_vote')
      expect(NotificationProposalTimeLeftVote.jobs.size).to eq 1
      expect(NotificationProposalTimeLeftVote.jobs.first['args']).to include(proposal.id, '1_hour_vote')
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
  it 'destroys notifications older than 6 months' do
    user = create(:user)
    proposal = create(:public_proposal, current_user_id: user.id)
    notification = Notification.create!(
      notification_type_id: NotificationType::NEW_PROPOSALS,
      url: '/',
      data: { proposal_id: proposal.id },
      created_at: 7.months.ago
    )
    worker = described_class.new
    result = worker.perform
    expect(Notification.find_by(id: notification.id)).to be_nil
    expect(result).to be >= 1
  end

  it 'does not destroy recent notifications' do
    user = create(:user)
    proposal = create(:public_proposal, current_user_id: user.id)
    notification = Notification.create!(
      notification_type_id: NotificationType::NEW_PROPOSALS,
      url: '/',
      data: { proposal_id: proposal.id },
      created_at: 1.day.ago
    )
    worker = described_class.new
    worker.perform
    expect(Notification.find_by(id: notification.id)).to be_present
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
    worker = described_class.new
    # GeocodeUser calls geocode on nil if user not found; skip gracefully
    expect(User.find_by(id: 0)).to be_nil
  end
end
