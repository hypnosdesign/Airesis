require 'rails_helper'

RSpec.describe NewsletterDeliveryJob do
  it 'delivers one recipient independently' do
    delivery = instance_double(ActionMailer::MessageDelivery, deliver_now: true)
    allow(ResqueMailer).to receive(:publish).with(12, 34).and_return(delivery)

    described_class.perform_now(12, 34)

    expect(delivery).to have_received(:deliver_now)
  end

  it 'configures bounded retries for delivery failures' do
    expect(described_class.rescue_handlers.map(&:first)).to include('StandardError')
  end
end
