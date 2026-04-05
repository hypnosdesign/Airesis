require 'rails_helper'
require 'requests_helper'

RSpec.describe NotificationProposalVoteClosed, type: :model, emails: true, notifications: true, seeds: true do
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
      create(:positive_ranking, proposal: proposal, user: u)
      u
    end
  end

  it 'sends notifications when vote closes on an accepted proposal' do
    described_class.perform_later(proposal.id)
    expect(described_class.jobs.size).to eq 1
    described_class.drain
    AlertsWorker.drain
    EmailsWorker.drain

    expect(Alert.unscoped.count).to be >= 1
    author_alert = Alert.unscoped.find_by(user: user)
    expect(author_alert.notification_type.id).to eq NotificationType::CHANGE_STATUS_MINE
  end

  it 'sends notifications when vote closes on a rejected proposal' do
    described_class.perform_later(proposal.id)
    described_class.drain
    AlertsWorker.drain
    EmailsWorker.drain

    expect(Alert.unscoped.count).to be >= 1
    author_alert = Alert.unscoped.find_by(user: user)
    expect(author_alert.notification_type.id).to eq NotificationType::CHANGE_STATUS_MINE
  end

  it 'includes group name in notification data' do
    described_class.perform_later(proposal.id)
    described_class.drain
    AlertsWorker.drain

    author_alert = Alert.find_by(user: user)
    expect(author_alert.data[:group]).to eq group.name
  end
end
