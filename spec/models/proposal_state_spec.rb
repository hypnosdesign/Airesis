require 'rails_helper'

RSpec.describe ProposalState, type: :model, seeds: true do
  describe 'constants' do
    it 'defines VALUTATION' do
      expect(ProposalState::VALUTATION).to be_present
    end

    it 'defines VOTING' do
      expect(ProposalState::VOTING).to be_present
    end

    it 'defines ACCEPTED' do
      expect(ProposalState::ACCEPTED).to be_present
    end

    it 'defines REJECTED' do
      expect(ProposalState::REJECTED).to be_present
    end

    it 'defines TAB_DEBATE' do
      expect(ProposalState::TAB_DEBATE).to be_present
    end

    it 'defines TAB_VOTATION' do
      expect(ProposalState::TAB_VOTATION).to be_present
    end

    it 'defines TAB_VOTED' do
      expect(ProposalState::TAB_VOTED).to be_present
    end
  end

  describe '.all' do
    it 'has seeded states' do
      expect(ProposalState.count).to be > 0
    end
  end
end
