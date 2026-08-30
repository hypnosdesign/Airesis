require 'rails_helper'

RSpec.describe AdminHelper, seeds: true do
  describe '.validate_groups' do
    it 'runs without error' do
      allow(ResqueMailer).to receive_message_chain(:admin_message, :deliver_later)
      expect { AdminHelper.validate_groups }.not_to raise_error
    end
  end

  describe '.calculate_ranking' do
    it 'runs without error' do
      allow(ResqueMailer).to receive_message_chain(:admin_message, :deliver_later)
      expect { AdminHelper.calculate_ranking }.not_to raise_error
    end
  end
end
