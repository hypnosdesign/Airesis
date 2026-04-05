require 'rails_helper'

RSpec.describe ProposalType, type: :model, seeds: true do
  describe '.all' do
    it 'has seeded proposal types' do
      expect(ProposalType.count).to be > 0
    end
  end

  describe 'constants' do
    it 'defines SIMPLE' do
      expect(ProposalType::SIMPLE).to be_present
    end

    it 'defines STANDARD' do
      expect(ProposalType::STANDARD).to be_present
    end
  end

  describe '#description' do
    it 'responds to description' do
      pt = ProposalType.first
      expect(pt).to respond_to(:description)
    end
  end

  describe 'scopes' do
    it 'has active scope' do
      expect(ProposalType.active).to respond_to(:each)
    end

    it 'has for_groups scope' do
      expect(ProposalType.for_groups).to respond_to(:each)
    end
  end
end
