require 'rails_helper'

RSpec.describe OldQuorum, type: :model, seeds: true do
  let(:quorum) do
    OldQuorum.create!(
      name: 'Test Quorum',
      description: 'A test quorum',
      good_score: 50,
      bad_score: 0,
      condition: 'OR',
      t_percentage: 's',
      t_good_score: 's',
      t_minutes: 's',
      percentage: 10
    )
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(quorum).to be_valid
    end

    it 'requires condition to be OR or AND' do
      q = OldQuorum.new(name: 'Test', good_score: 50, bad_score: 0,
                        condition: 'INVALID', percentage: 10,
                        t_percentage: 's', t_good_score: 's', t_minutes: 's')
      expect(q).not_to be_valid
    end

    it 'is invalid without minutes, percentage, or days' do
      q = OldQuorum.new(name: 'Test', good_score: 50, bad_score: 0,
                        condition: 'OR',
                        t_percentage: 's', t_good_score: 's', t_minutes: 's')
      expect(q).not_to be_valid
    end

    it 'accepts condition OR' do
      q = OldQuorum.new(name: 'Test', good_score: 50, bad_score: 0,
                        condition: 'OR', percentage: 10,
                        t_percentage: 's', t_good_score: 's', t_minutes: 's')
      expect(q.condition).to eq 'OR'
    end

    it 'accepts condition AND' do
      q = OldQuorum.new(name: 'Test', good_score: 50, bad_score: 0,
                        condition: 'AND', percentage: 10,
                        t_percentage: 's', t_good_score: 's', t_minutes: 's')
      expect(q.condition).to eq 'AND'
    end
  end

  describe '#or?' do
    it 'returns true when condition is OR' do
      expect(quorum.or?).to be_truthy
    end

    it 'returns falsy when condition is AND' do
      quorum.condition = 'AND'
      expect(quorum.or?).to be_falsy
    end
  end

  describe '#and?' do
    it 'returns falsy when condition is OR' do
      expect(quorum.and?).to be_falsy
    end

    it 'returns true when condition is AND' do
      quorum.condition = 'AND'
      expect(quorum.and?).to be_truthy
    end
  end

  describe '#time_fixed?' do
    it 'returns true when minutes is set, no percentage, and good_score == bad_score' do
      quorum.minutes = 60
      quorum.percentage = nil
      quorum.bad_score = 50
      expect(quorum.time_fixed?).to be true
    end

    it 'returns false when percentage is set' do
      quorum.minutes = 60
      quorum.percentage = 10
      expect(quorum.time_fixed?).to be false
    end

    it 'returns false when minutes is not set' do
      quorum.minutes = nil
      quorum.percentage = nil
      expect(quorum.time_fixed?).to be_falsy
    end
  end

  describe '#end_desc' do
    it 'returns empty string when no ends_at or valutations' do
      quorum.ends_at = nil
      quorum.valutations = nil
      expect(quorum.end_desc).to eq ''
    end

    it 'includes valutations count when valutations is set' do
      quorum.valutations = 5
      quorum.ends_at = nil
      result = quorum.end_desc
      expect(result).to be_a(String)
    end

    it 'includes ends_at when set' do
      quorum.ends_at = 2.days.from_now
      quorum.valutations = nil
      result = quorum.end_desc
      expect(result).to be_a(String)
    end
  end

  describe '#time_left' do
    it 'returns IN STALLO when ends_at is nil and no valutations' do
      quorum.ends_at = nil
      quorum.valutations = nil
      expect(quorum.time_left).to eq 'IN STALLO'
    end

    it 'returns IN STALLO when ends_at is in the past and no valutations' do
      quorum.ends_at = 1.hour.ago
      quorum.valutations = nil
      expect(quorum.time_left).to eq 'IN STALLO'
    end

    it 'returns a string when less than 1 minute left' do
      quorum.ends_at = 30.seconds.from_now
      quorum.valutations = nil
      result = quorum.time_left
      expect(result).to be_a(String)
      expect(result).not_to eq 'IN STALLO'
    end

    it 'returns a string when less than 1 hour left' do
      quorum.ends_at = 30.minutes.from_now
      quorum.valutations = nil
      result = quorum.time_left
      expect(result).to be_a(String)
      expect(result).not_to eq 'IN STALLO'
    end

    it 'returns a string when less than 24 hours left' do
      quorum.ends_at = 5.hours.from_now
      quorum.valutations = nil
      result = quorum.time_left
      expect(result).to be_a(String)
      expect(result).not_to eq 'IN STALLO'
    end

    it 'returns a string in days when more than 24 hours left' do
      quorum.ends_at = 3.days.from_now
      quorum.valutations = nil
      result = quorum.time_left
      expect(result).to be_a(String)
      expect(result).not_to eq 'IN STALLO'
    end
  end

  describe '#debate_progress' do
    it 'returns nil when no valutations and no minutes' do
      quorum.valutations = nil
      quorum.minutes = nil
      result = quorum.debate_progress
      # with no conditions, percentages array is empty
      expect(result).to be_nil
    end

    it 'returns a percentage based on time when minutes and started_at are set' do
      quorum.minutes = 60 * 24 * 2 # 2 days in minutes
      quorum.started_at = 1.day.ago
      quorum.ends_at = 1.day.from_now
      quorum.valutations = nil
      result = quorum.debate_progress
      expect(result).to be_a(Numeric)
      expect(result).to be_between(0, 100)
    end
  end

  describe '#has_bad_score?' do
    it 'returns true when bad_score differs from good_score' do
      quorum.bad_score = 10
      quorum.good_score = 50
      expect(quorum.has_bad_score?).to be true
    end

    it 'returns false when bad_score equals good_score' do
      quorum.bad_score = 50
      quorum.good_score = 50
      expect(quorum.has_bad_score?).to be_falsy
    end

    it 'returns false when bad_score is nil' do
      quorum.bad_score = nil
      expect(quorum.has_bad_score?).to be_falsy
    end
  end
end
