require 'rails_helper'

# Stub Resque::Failure::Base before loading the lib file
module Resque
  module Failure
    class Base
      attr_reader :exception, :worker, :queue, :payload

      def initialize(exception, worker, queue, payload, *args)
        @exception = exception
        @worker = worker
        @queue = queue
        @payload = payload
      end
    end

    class Multiple; end
  end

  def self.Failure
    Failure
  end
end

# Stub the backend accessor
module Resque
  module Failure
    class << self
      attr_accessor :backend
    end
  end
end

require Rails.root.join('lib/resque/failure/notifier2').to_s

RSpec.describe Resque::Failure::Notifier2 do
  before do
    described_class.smtp = { address: 'smtp.example.com', port: 25, user: 'user', secret: 'pass' }
    described_class.sender = 'noreply@example.com'
    described_class.recipients = ['admin@example.com']
  end

  describe '.configure' do
    it 'yields self and sets backend' do
      described_class.configure do |c|
        expect(c).to eq(described_class)
      end
    end
  end

  describe '#save' do
    let(:exception) do
      begin
        raise RuntimeError, 'something went wrong'
      rescue => e
        e
      end
    end

    let(:notifier) do
      described_class.new(exception, 'Worker:test-queue:1', 'test-queue', { 'class' => 'TestWorker', 'args' => [] })
    end

    it 'sends an email via SMTP' do
      smtp_double = double('smtp')
      allow(smtp_double).to receive(:send_message)
      allow(Net::SMTP).to receive(:start).and_yield(smtp_double)

      notifier.save

      expect(smtp_double).to have_received(:send_message)
    end

    it 'rescues errors gracefully when SMTP fails' do
      allow(Net::SMTP).to receive(:start).and_raise(StandardError, 'connection refused')

      expect { notifier.save }.not_to raise_error
    end
  end
end
