require 'rails_helper'
require 'requests_helper'

RSpec.describe NotificationProposalRejected, type: :model, emails: true, notifications: true, seeds: true do
  it 'sends notifications to authors and participants when a proposal is rejected' do
    user = create(:user)
    group = create(:group, current_user_id: user.id)
    proposal = create(:group_proposal, current_user_id: user.id, group_proposals: [GroupProposal.new(group: group)])

    participants = 2.times.map do
      u = create(:user)
      create_participation(u, group)
      create(:positive_ranking, proposal: proposal, user: u)
      u
    end

    described_class.perform_async(proposal.id)
    expect(described_class.jobs.size).to eq 1
    described_class.drain
    AlertsWorker.drain
    EmailsWorker.drain

    # author + 2 participants = 3 alerts
    expect(Alert.unscoped.count).to eq 3
    author_alert = Alert.unscoped.find_by(user: user)
    expect(author_alert.notification_type.id).to eq NotificationType::CHANGE_STATUS_MINE

    participant_alerts = Alert.unscoped.where(user: participants)
    expect(participant_alerts.count).to eq 2
    expect(participant_alerts.map { |a| a.notification_type.id }.uniq).to eq [NotificationType::CHANGE_STATUS]
  end

  it 'includes the group name in notification data when proposal belongs to a group' do
    user = create(:user)
    group = create(:group, current_user_id: user.id)
    proposal = create(:group_proposal, current_user_id: user.id, group_proposals: [GroupProposal.new(group: group)])

    described_class.perform_async(proposal.id)
    described_class.drain
    AlertsWorker.drain

    alert = Alert.find_by(user: user)
    expect(alert.data[:group]).to eq group.name
  end
end
