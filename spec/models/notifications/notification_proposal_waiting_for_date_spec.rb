require 'rails_helper'
require 'requests_helper'

RSpec.describe NotificationProposalWaitingForDate, type: :model, emails: true, notifications: true, seeds: true do
  let!(:current_user) { create(:user) }
  let!(:group) { create(:group, current_user_id: current_user.id) }
  let!(:proposal) do
    create(:group_proposal, current_user_id: current_user.id,
           group_proposals: [GroupProposal.new(group: group)]).reload
  end

  let!(:participants) do
    2.times.map do
      u = create(:user)
      create_participation(u, group)
      create(:positive_ranking, proposal: proposal, user: u)
      u
    end
  end

  it 'notifies participants when a proposal is waiting for a vote date' do
    described_class.perform_later(proposal.id, current_user.id)
    expect(described_class.jobs.size).to eq 1
    described_class.drain
    AlertsWorker.drain
    EmailsWorker.drain

    # participants (excluding the current user) get notified
    expect(Alert.unscoped.count).to eq 2
    alert_users = Alert.unscoped.map(&:user)
    expect(alert_users).to match_array participants
    Alert.unscoped.each do |alert|
      expect(alert.notification_type.id).to eq NotificationType::CHANGE_STATUS
    end
  end

  it 'includes the author name in notification data' do
    described_class.perform_later(proposal.id, current_user.id)
    described_class.drain
    AlertsWorker.drain

    alert = Alert.first
    expect(alert.data[:name]).to be_present
  end

  it 'includes group name when proposal is in a group' do
    described_class.perform_later(proposal.id, current_user.id)
    described_class.drain
    AlertsWorker.drain

    alert = Alert.first
    expect(alert.data[:group]).to eq group.name
  end
end
