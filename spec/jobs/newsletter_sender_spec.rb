require 'rails_helper'

RSpec.describe NewsletterSender do
  it 'fans a batch out into independently retryable delivery jobs' do
    expect do
      described_class.perform_now(12, [34, 56, 34])
    end.to have_enqueued_job(NewsletterDeliveryJob).exactly(2).times

    expect(NewsletterDeliveryJob).to have_been_enqueued.with(12, 34)
    expect(NewsletterDeliveryJob).to have_been_enqueued.with(12, 56)
  end
end
