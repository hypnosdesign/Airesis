require 'rails_helper'

RSpec.describe Meeting do
  it 'can be built' do
    expect(create(:meeting)).to be_valid
  end

  describe 'associations' do
    it { is_expected.to belong_to(:place) }
    it { is_expected.to belong_to(:event) }
    it { is_expected.to have_many(:meeting_participations) }
  end

  describe 'nested attributes' do
    it 'accepts nested attributes for place' do
      expect(Meeting.new).to respond_to(:place_attributes=)
    end
  end
end
