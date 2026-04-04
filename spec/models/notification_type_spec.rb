require 'rails_helper'

RSpec.describe NotificationType, type: :model, seeds: true do
  describe 'associations' do
    it { is_expected.to belong_to(:notification_category) }
  end

  describe '.all' do
    it 'returns notification types' do
      expect(NotificationType.count).to be > 0
    end
  end
end
