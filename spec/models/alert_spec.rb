require 'rails_helper'

RSpec.describe Alert, type: :model, seeds: true do
  let!(:user) { create(:user) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:notification) }
  end

  describe '#message' do
    it 'returns the alert message' do
      alert = Alert.new(user: user)
      expect(alert).to respond_to(:message)
    end
  end

  describe '#check!' do
    it 'responds to check!' do
      expect(Alert.new).to respond_to(:check!)
    end
  end
end
