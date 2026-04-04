require 'rails_helper'

RSpec.describe Announcement do
  context 'validations' do
    it { is_expected.to validate_presence_of(:starts_at) }
    it { is_expected.to validate_presence_of(:ends_at) }
    it { is_expected.to validate_presence_of(:message) }
    it { is_expected.to validate_length_of(:message).is_at_most(10.kilobytes) }
  end

  describe '.current' do
    let!(:active) do
      Announcement.create!(message: 'Active', starts_at: 1.day.ago, ends_at: 1.day.from_now)
    end
    let!(:past) do
      Announcement.create!(message: 'Past', starts_at: 2.days.ago, ends_at: 1.day.ago)
    end

    it 'returns active announcements' do
      expect(described_class.current).to include(active)
      expect(described_class.current).not_to include(past)
    end

    it 'excludes announcements with hidden_ids' do
      result = described_class.current([active.id])
      expect(result).not_to include(active)
    end
  end
end
