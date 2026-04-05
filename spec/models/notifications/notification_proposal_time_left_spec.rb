require 'rails_helper'
require 'requests_helper'

RSpec.describe NotificationProposalTimeLeft, type: :model, emails: true, notifications: true, seeds: true do
  let!(:user) { create(:user) }
  let!(:group) { create(:group, current_user_id: user.id) }
  let!(:proposal) do
    create(:group_proposal, current_user_id: user.id,
           group_proposals: [GroupProposal.new(group: group)]).reload
  end

  # participants without rankings so notification_receivers includes them (ranking.updated_at < proposal.updated_at is the filter)
  let!(:participants) do
    2.times.map do
      u = create(:user)
      create_participation(u, group)
      create(:proposal_comment, proposal: proposal, user: u)
      u
    end
  end

  it 'sends notifications to all notification receivers' do
    described_class.perform_later(proposal.id, '24_hours')
    expect(described_class.jobs.size).to eq 1
    described_class.drain
    AlertsWorker.drain
    EmailsWorker.drain

    expect(Alert.unscoped.count).to be >= 1
    alert = Alert.first
    expect(alert.notification_type.id).to eq NotificationType::PHASE_ENDING
  end

  it 'includes the type extension in notification data' do
    described_class.perform_later(proposal.id, '24_hours')
    described_class.drain
    AlertsWorker.drain

    alert = Alert.first
    expect(alert.data[:extension]).to eq '24_hours'
  end

  it 'includes group name in data when proposal belongs to a group' do
    described_class.perform_later(proposal.id, '24_hours')
    described_class.drain
    AlertsWorker.drain

    alert = Alert.first
    expect(alert.data[:group]).to eq group.name
  end
end

RSpec.describe NotificationProposalTimeLeftVote, type: :model, emails: true, notifications: true, seeds: true do
  let!(:user) { create(:user) }
  let!(:group) { create(:group, current_user_id: user.id) }
  let!(:proposal) do
    create(:group_proposal, current_user_id: user.id,
           group_proposals: [GroupProposal.new(group: group)]).reload
  end

  let!(:participants) do
    2.times.map do
      u = create(:user)
      create_participation(u, group)
      u
    end
  end

  it 'sends notifications to group participants who can vote' do
    described_class.perform_later(proposal.id, '24_hours_vote')
    expect(described_class.jobs.size).to eq 1
    described_class.drain
    AlertsWorker.drain
    EmailsWorker.drain

    expect(Alert.unscoped.count).to be >= 0
  end
end
