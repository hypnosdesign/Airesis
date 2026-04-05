require 'rails_helper'

RSpec.describe BlogComment do
  context 'validations' do
    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_length_of(:body).is_at_most(10.kilobytes) }
  end

  describe '#formatted_created_at' do
    it 'returns a formatted string' do
      comment = create(:blog_comment)
      expect(comment.formatted_created_at).to be_a(String)
      expect(comment.formatted_created_at).to match(%r{\d{2}/\d{2}/\d{4}})
    end
  end

  describe '#parsed_body' do
    it 'returns the body content' do
      comment = build(:blog_comment, body: 'Test comment body')
      expect(comment.parsed_body).to eq('Test comment body')
    end
  end

  describe '#user_name' do
    it 'returns the user name' do
      user = create(:user)
      comment = build(:blog_comment, user: user)
      expect(comment.user_name).to include(user.name)
    end
  end

  describe '#collapsed' do
    it 'defaults to false after initialization' do
      comment = BlogComment.new
      comment.after_initialize
      expect(comment.collapsed).to be false
    end

    it 'can be set to true' do
      comment = BlogComment.new
      comment.collapsed = true
      expect(comment.collapsed).to be true
    end
  end

  describe '#request=' do
    it 'sets user_ip, user_agent and referrer from request object' do
      comment = BlogComment.new
      request = double('request',
        remote_ip: '127.0.0.1',
        env: { 'HTTP_USER_AGENT' => 'Mozilla/5.0', 'HTTP_REFERER' => 'http://example.com' }
      )
      comment.request = request
      expect(comment.user_ip).to eq('127.0.0.1')
      expect(comment.user_agent).to eq('Mozilla/5.0')
      expect(comment.referrer).to eq('http://example.com')
    end
  end
end
