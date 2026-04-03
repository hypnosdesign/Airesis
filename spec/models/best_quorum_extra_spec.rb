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
end
