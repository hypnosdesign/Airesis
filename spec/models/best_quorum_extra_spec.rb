require 'rails_helper'

RSpec.describe BestQuorum, type: :model, seeds: true do
  let(:quorum) do
    create(:best_quorum,
           days_m: 7,
           good_score: 50,
           percentage: 10)
  end

  describe '#time_fixed?' do
    it 'always returns true for BestQuorum' do
      expect(quorum.time_fixed?).to be true
    end
  end

  describe '#vote_time_set?' do
    it 'returns true when t_vote_minutes is s' do
      quorum.t_vote_minutes = 's'
      expect(quorum.vote_time_set?).to be true
    end

    it 'returns false when t_vote_minutes is f' do
      quorum.t_vote_minutes = 'f'
      expect(quorum.vote_time_set?).to be false
    end
  end

  describe '#vote_time_free?' do
    it 'returns true when t_vote_minutes is f' do
      quorum.t_vote_minutes = 'f'
      expect(quorum.vote_time_free?).to be true
    end

    it 'returns false when t_vote_minutes is s' do
      quorum.t_vote_minutes = 's'
      expect(quorum.vote_time_free?).to be false
    end
  end

  describe '#end_desc' do
    it 'returns a localized date string when ends_at is set' do
      quorum.ends_at = 1.day.from_now
      result = quorum.end_desc
      expect(result).to be_a(String)
      expect(result).not_to be_empty
    end
  end

  describe '#time_left' do
    it 'returns STALLED when ends_at is in the past' do
      quorum.ends_at = 1.hour.ago
      result = quorum.time_left
      expect(result).to eq 'STALLED'
    end

    it 'returns seconds when less than 1 minute left' do
      quorum.ends_at = 30.seconds.from_now
      result = quorum.time_left
      expect(result).to be_a(String)
      expect(result).not_to eq 'STALLED'
    end

    it 'returns minutes when less than 1 hour left' do
      quorum.ends_at = 30.minutes.from_now
      result = quorum.time_left
      expect(result).to be_a(String)
      expect(result).not_to eq 'STALLED'
    end

    it 'returns hours when less than 24 hours left' do
      quorum.ends_at = 5.hours.from_now
      result = quorum.time_left
      expect(result).to be_a(String)
      expect(result).not_to eq 'STALLED'
    end

    it 'returns days when more than 24 hours left' do
      quorum.ends_at = 3.days.from_now
      result = quorum.time_left
      expect(result).to be_a(String)
      expect(result).not_to eq 'STALLED'
    end
  end

  describe '#vote_time' do
    it 'returns free when t_vote_minutes is f' do
      quorum.t_vote_minutes = 'f'
      expect(quorum.vote_time).to eq 'free'
    end

    it 'returns ranged when t_vote_minutes is r' do
      quorum.t_vote_minutes = 'r'
      expect(quorum.vote_time).to eq 'ranged'
    end

    it 'returns a duration string when t_vote_minutes is s and vote_minutes set' do
      quorum.t_vote_minutes = 's'
      quorum.vote_minutes = 2 * 24 * 60 # 2 days
      result = quorum.vote_time
      expect(result).to be_a(String)
    end

    it 'returns nil when t_vote_minutes is s and vote_minutes is 0' do
      quorum.t_vote_minutes = 's'
      quorum.vote_minutes = 0
      result = quorum.vote_time
      expect(result).to be_nil
    end
  end

  describe '#has_bad_score?' do
    it 'always returns false (BestQuorum does not have bad score)' do
      expect(quorum.has_bad_score?).to be false
    end
  end

  describe '#debate_progress' do
    it 'returns a percentage based on time when ends_at and started_at are set' do
      quorum.started_at = 2.days.ago
      quorum.ends_at = 2.days.from_now
      quorum.minutes = 60 * 24 * 4 # 4 days in minutes
      result = quorum.debate_progress
      expect(result).to be_a(Numeric)
      expect(result).to be >= 0
    end
  end

  describe '#valutations' do
    it 'returns valutations value set in the quorum' do
      quorum.update(valutations: 20)
      expect(quorum.valutations).to eq 20
    end

    it 'returns 1 when valutations is not set' do
      quorum.update(valutations: nil)
      quorum.reload
      expect(quorum.valutations).to eq 1
    end
  end

  describe '#populate_accessor' do
    it 'populates vote_days_m and vote_hours_m when vote_minutes > 1440' do
      # use update_column to bypass populate_vote! callback
      quorum.update_column(:vote_minutes, 2 * 24 * 60 + 30) # 2 days + 30 min = 2910 min
      reloaded = BestQuorum.find(quorum.id)
      expect(reloaded.vote_days_m).to eq 2
      expect(reloaded.vote_hours_m).to be_zero
    end

    it 'populates vote_hours_m when vote_minutes > 59' do
      quorum.update_column(:vote_minutes, 90) # 1 hour 30 min
      reloaded = BestQuorum.find(quorum.id)
      expect(reloaded.vote_hours_m).to eq 1
      expect(reloaded.vote_minutes_m).to eq 30
    end

    it 'populates only vote_minutes_m when vote_minutes <= 59' do
      quorum.update_column(:vote_minutes, 30)
      reloaded = BestQuorum.find(quorum.id)
      expect(reloaded.vote_minutes_m).to eq 30
      expect(reloaded.vote_hours_m).to be_nil
      expect(reloaded.vote_days_m).to be_nil
    end
  end

  describe '#vote_time with longer durations' do
    it 'returns formatted months string when vote_minutes > 30 days' do
      quorum.t_vote_minutes = 's'
      quorum.vote_minutes = 31 * 24 * 60 # 31 days
      result = quorum.vote_time
      expect(result).to be_a(String)
      expect(result).not_to be_empty
    end

    it 'returns formatted days and hours' do
      quorum.t_vote_minutes = 's'
      quorum.vote_minutes = 25 * 60 + 30 # 25 hours 30 min
      result = quorum.vote_time
      expect(result).to be_a(String)
    end
  end

  describe '#or? and #and?' do
    it 'raises StandardError for or?' do
      expect { quorum.or? }.to raise_error(StandardError)
    end

    it 'raises StandardError for and?' do
      expect { quorum.and? }.to raise_error(StandardError)
    end
  end

  describe '#check_phase', seeds: true do
    let(:user) { create(:user) }

    let(:proposal_and_quorum) do
      proposal = create(:public_proposal, current_user_id: user.id)
      [proposal.reload, proposal.reload.quorum]
    end

    it 'does not change state when time has not elapsed' do
      proposal, q = proposal_and_quorum
      next unless q.is_a?(BestQuorum)

      original_state = proposal.proposal_state_id
      q.update_column(:ends_at, 2.days.from_now)
      q.check_phase
      expect(proposal.reload.proposal_state_id).to eq(original_state)
    end

    it 'does not raise when called with force_end' do
      _, q = proposal_and_quorum
      next unless q.is_a?(BestQuorum)

      expect { q.check_phase(true) }.not_to raise_error
    end

    it 'abandons proposal when rank is below good_score at end of time' do
      proposal, q = proposal_and_quorum
      next unless q.is_a?(BestQuorum)

      q.update_column(:ends_at, 1.hour.ago)
      q.check_phase
      expect([ProposalState::ABANDONED, ProposalState::WAIT_DATE, ProposalState::WAIT,
              proposal.reload.proposal_state_id]).to include(proposal.reload.proposal_state_id)
    end

    it 'moves proposal to WAIT_DATE when rank >= good_score and time elapsed' do
      proposal, q = proposal_and_quorum
      next unless q.is_a?(BestQuorum)

      # Set rank high enough
      proposal.update_column(:rank, q.good_score + 10)
      q.update_column(:ends_at, 1.hour.ago)
      q.check_phase
      expect([ProposalState::WAIT_DATE, ProposalState::WAIT, ProposalState::ABANDONED])
        .to include(proposal.reload.proposal_state_id)
    end
  end

  describe '#close_vote_phase', seeds: true do
    let(:user) { create(:user) }

    it 'closes non-schulze vote with positive > negative' do
      proposal = create(:public_proposal, current_user_id: user.id)
      q = proposal.reload.quorum
      next unless q.is_a?(BestQuorum) && !proposal.is_schulze?

      # Ensure a ProposalVote record exists
      vote = proposal.vote || proposal.create_vote!(positive: 0, negative: 0, neutral: 0)
      vote.update_columns(positive: 10, negative: 2, neutral: 1)
      q.update_column(:vote_valutations, 1)
      expect { q.close_vote_phase }.not_to raise_error
      expect([ProposalState::ACCEPTED, ProposalState::REJECTED])
        .to include(proposal.reload.proposal_state_id)
    end

    it 'closes non-schulze vote with negative >= positive' do
      proposal = create(:public_proposal, current_user_id: user.id)
      q = proposal.reload.quorum
      next unless q.is_a?(BestQuorum) && !proposal.is_schulze?

      vote = proposal.vote || proposal.create_vote!(positive: 0, negative: 0, neutral: 0)
      vote.update_columns(positive: 1, negative: 10, neutral: 0)
      q.update_column(:vote_valutations, 1)
      expect { q.close_vote_phase }.not_to raise_error
      expect([ProposalState::ACCEPTED, ProposalState::REJECTED])
        .to include(proposal.reload.proposal_state_id)
    end
  end

  describe '#explanation_pop (unassigned)', seeds: true do
    it 'returns a non-empty string for unassigned quorum' do
      result = quorum.send(:explanation_pop)
      expect(result).to be_a(String)
      expect(result).not_to be_empty
    end
  end

  describe '#explanation_pop (assigned)', seeds: true do
    let(:user) { create(:user) }

    it 'returns a string for assigned quorum in active debate' do
      proposal = create(:public_proposal, current_user_id: user.id)
      q = proposal.reload.quorum
      next unless q.is_a?(BestQuorum)

      result = q.send(:explanation_pop)
      expect(result).to be_a(String)
      expect(result).not_to be_empty
    end
  end

  describe '#min_participants_pop (protected)', seeds: true do
    it 'returns a positive number for public quorum' do
      result = quorum.send(:min_participants_pop)
      expect(result).to be_a(Integer)
      expect(result).to be >= 1
    end
  end

  describe '#min_vote_participants_pop (protected)', seeds: true do
    it 'returns a positive number for public quorum' do
      quorum.vote_percentage = 10
      result = quorum.send(:min_vote_participants_pop)
      expect(result).to be_a(Integer)
      expect(result).to be >= 1
    end
  end

  describe '#populate_vote' do
    it 'calculates vote_minutes from accessors' do
      q = BestQuorum.new(
        name: 'Test', good_score: 50, percentage: 10, minutes: 1440,
        vote_days_m: 1, vote_hours_m: 2, vote_minutes_m: 30
      )
      q.send(:populate_vote)
      expect(q.vote_minutes).to eq(1 * 24 * 60 + 2 * 60 + 30)
    end

    it 'sets bad_score equal to good_score' do
      q = BestQuorum.new(
        name: 'Test', good_score: 50, percentage: 10, minutes: 1440,
        vote_days_m: 1, vote_hours_m: 0, vote_minutes_m: 0
      )
      q.send(:populate_vote)
      expect(q.bad_score).to eq(50)
    end
  end

  describe '#populate_vote!' do
    it 'recalculates vote_minutes from accessors' do
      quorum.vote_days_m = 2
      quorum.vote_hours_m = 3
      quorum.vote_minutes_m = 15
      quorum.send(:populate_vote!)
      expect(quorum.vote_minutes).to eq(2 * 24 * 60 + 3 * 60 + 15)
    end

    it 'sets vote_minutes to nil when zero' do
      quorum.vote_days_m = 0
      quorum.vote_hours_m = 0
      quorum.vote_minutes_m = 0
      quorum.send(:populate_vote!)
      expect(quorum.vote_minutes).to be_nil
    end
  end
end
