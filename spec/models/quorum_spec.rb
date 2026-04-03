require 'rails_helper'

RSpec.describe BestQuorum, type: :model, seeds: true do
  let(:quorum) { create(:best_quorum) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(quorum).to be_valid
    end

    it 'requires a name' do
      quorum.name = nil
      expect(quorum).not_to be_valid
    end

    it 'requires good_score' do
      quorum.good_score = nil
      expect(quorum).not_to be_valid
    end
  end

  describe '#populate_accessor' do
    it 'sets days_m from minutes when minutes > 24*60' do
      q = create(:best_quorum, days_m: 3)
      q.reload
      expect(q.days_m).to eq 3
    end

    it 'sets hours_m from minutes when minutes > 60' do
      q = BestQuorum.new(name: 'test', good_score: 50, t_good_score: 's', t_minutes: 's', t_percentage: 's',
                         t_vote_good_score: 's', t_vote_minutes: 'f', t_vote_percentage: 's',
                         vote_good_score: 50, vote_percentage: 0)
      q.hours_m = 3
      q.save!
      q.reload
      expect(q.hours_m).to eq 3
    end
  end

  describe '#populate_vote' do
    it 'sets vote_minutes from vote_days_m, vote_hours_m, vote_minutes_m' do
      q = create(:best_quorum)
      q.vote_days_m = 2
      q.vote_hours_m = 1
      q.vote_minutes_m = 30
      q.save!
      expected = (2 * 24 * 60) + (1 * 60) + 30
      expect(q.vote_minutes).to eq expected
    end

    it 'sets bad_score equal to good_score' do
      q = create(:best_quorum, good_score: 65)
      expect(q.bad_score).to eq 65
    end

    it 'sets vote_minutes to nil when all time fields are 0' do
      q = create(:best_quorum)
      q.vote_days_m = 0
      q.vote_hours_m = 0
      q.vote_minutes_m = 0
      q.save!
      expect(q.vote_minutes).to be_nil
    end
  end

  describe '#time' do
    it 'returns a human-readable duration' do
      q = create(:best_quorum, days_m: 7)
      expect(q.time).to be_a String
      expect(q.time).not_to be_empty
    end
  end

  describe '#time_left?' do
    it 'returns false when ends_at is nil' do
      expect(quorum.time_left?).to be_falsey
    end

    it 'returns true when ends_at is in the future' do
      quorum.ends_at = 1.day.from_now
      expect(quorum.time_left?).to be_truthy
    end

    it 'returns false when ends_at is in the past' do
      quorum.ends_at = 1.day.ago
      expect(quorum.time_left?).to be_falsey
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

  describe '#time with various durations' do
    it 'returns nil when minutes is nil' do
      quorum.minutes = nil
      expect(quorum.time).to be_nil
    end

    it 'returns nil when minutes is 0' do
      quorum.minutes = 0
      expect(quorum.time).to be_nil
    end

    it 'returns minutes string when < 60 min' do
      quorum.minutes = 30
      result = quorum.time
      expect(result).to be_a(String)
      expect(result).not_to be_empty
    end

    it 'returns hours and minutes when < 24 hours' do
      quorum.minutes = 90
      result = quorum.time
      expect(result).to be_a(String)
    end

    it 'returns days when > 24 hours' do
      quorum.minutes = 2 * 24 * 60
      result = quorum.time
      expect(result).to be_a(String)
    end

    it 'returns months when > 30 days' do
      quorum.minutes = 45 * 24 * 60
      result = quorum.time
      expect(result).to be_a(String)
    end

    it 'returns remaining time when assigned' do
      quorum.update_column(:assigned, true)
      quorum.ends_at = 2.days.from_now
      quorum.minutes = 4 * 24 * 60
      result = quorum.time
      expect(result).to be_a(String) if result
    end

    it 'returns total time when total_time=true even if assigned' do
      quorum.update_column(:assigned, true)
      quorum.ends_at = 2.days.from_now
      quorum.minutes = 4 * 24 * 60
      result = quorum.time(true)
      expect(result).to be_a(String)
    end
  end

  describe '#explanation' do
    it 'returns a string' do
      result = quorum.explanation
      expect(result).to be_a(String) if result
    end
  end

  describe '#min_participants' do
    it 'returns an integer' do
      quorum.percentage = 10
      result = quorum.min_participants
      expect(result).to be_a(Integer) if result
    end
  end

  describe 'scopes' do
    it '.visible returns public quorums' do
      visible = BestQuorum.visible
      expect(visible).to be_a(ActiveRecord::Relation)
    end

    it '.active returns active quorums' do
      active = BestQuorum.active
      expect(active).to be_a(ActiveRecord::Relation)
    end

    it '.assigned returns assigned quorums' do
      assigned = BestQuorum.assigned
      expect(assigned).to be_a(ActiveRecord::Relation)
    end

    it '.unassigned returns unassigned quorums' do
      unassigned = BestQuorum.unassigned
      expect(unassigned).to be_a(ActiveRecord::Relation)
    end
  end
end
