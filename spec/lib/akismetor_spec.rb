require 'rails_helper'
require 'akismetor'

RSpec.describe Akismetor do
  let(:attributes) do
    {
      key: 'test-api-key',
      blog: 'http://example.com',
      user_ip: '127.0.0.1',
      comment_content: 'Test comment'
    }
  end

  # Note: lib/akismetor.rb uses URI.escape which was removed in Ruby 3.x.
  # Tests stub attributes_for_post to bypass that issue.

  before do
    allow_any_instance_of(Akismetor).to receive(:attributes_for_post).and_return('key=value&blog=http%3A%2F%2Fexample.com')
  end

  describe '.initialize' do
    it 'stores attributes' do
      instance = Akismetor.new(attributes)
      expect(instance.attributes).to eq(attributes)
    end
  end

  describe '.valid_key?' do
    it 'calls execute with verify-key command and returns response body' do
      response_double = double(body: 'valid')
      allow_any_instance_of(Net::HTTP).to receive(:post).and_return(response_double)

      result = Akismetor.valid_key?(attributes)
      expect(result).to eq('valid')
    end
  end

  describe '.spam?' do
    it 'returns true when response is not "false"' do
      response_double = double(body: 'true')
      allow_any_instance_of(Net::HTTP).to receive(:post).and_return(response_double)

      expect(Akismetor.spam?(attributes)).to be true
    end

    it 'returns false when response is "false"' do
      response_double = double(body: 'false')
      allow_any_instance_of(Net::HTTP).to receive(:post).and_return(response_double)

      expect(Akismetor.spam?(attributes)).to be false
    end
  end

  describe '.submit_spam' do
    it 'calls execute with submit-spam command' do
      response_double = double(body: 'Thanks for making the web a better place.')
      allow_any_instance_of(Net::HTTP).to receive(:post).and_return(response_double)

      result = Akismetor.submit_spam(attributes)
      expect(result).to be_a(String)
    end
  end

  describe '.submit_ham' do
    it 'calls execute with submit-ham command' do
      response_double = double(body: 'Thanks for making the web a better place.')
      allow_any_instance_of(Net::HTTP).to receive(:post).and_return(response_double)

      result = Akismetor.submit_ham(attributes)
      expect(result).to be_a(String)
    end
  end

  describe '#execute' do
    it 'uses host prefix with key for non-verify-key commands' do
      response_double = double(body: 'ok')
      expect(Net::HTTP).to receive(:new).with('test-api-key.rest.akismet.com', 80).and_call_original
      allow_any_instance_of(Net::HTTP).to receive(:post).and_return(response_double)
      Akismetor.new(attributes).execute('comment-check')
    end

    it 'does not use key prefix for verify-key command' do
      response_double = double(body: 'valid')
      expect(Net::HTTP).to receive(:new).with('rest.akismet.com', 80).and_call_original
      allow_any_instance_of(Net::HTTP).to receive(:post).and_return(response_double)
      Akismetor.new(attributes).execute('verify-key')
    end
  end
end
