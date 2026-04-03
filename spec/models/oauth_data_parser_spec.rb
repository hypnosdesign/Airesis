require 'rails_helper'

RSpec.describe OauthDataParser, type: :model do
  let(:google_data) do
    {
      'provider' => 'google_oauth2',
      'uid' => '12345',
      'extra' => {
        'raw_info' => {
          'email' => 'user@example.com',
          'first_name' => 'John',
          'last_name' => 'Doe',
          'gender' => 'male',
          'picture' => 'https://example.com/photo.jpg'
        }
      },
      'info' => { 'image' => 'https://example.com/image.jpg' }
    }
  end

  let(:twitter_data) do
    {
      'provider' => 'twitter',
      'uid' => '67890',
      'extra' => {
        'raw_info' => {
          'name' => 'Jane Smith',
          'email' => nil,
          'profile_image_url' => 'https://pbs.twimg.com/profile.jpg'
        }
      },
      'info' => {}
    }
  end

  let(:facebook_data) do
    {
      'provider' => 'facebook',
      'uid' => '11111',
      'extra' => {
        'raw_info' => {
          'email' => 'fb@example.com',
          'first_name' => 'Alice',
          'last_name' => 'Wonder',
          'gender' => 'female',
          'verified' => true
        }
      },
      'info' => { 'image' => 'https://graph.facebook.com/photo' }
    }
  end

  describe '#provider' do
    it 'returns the provider string' do
      parser = OauthDataParser.new(google_data)
      expect(parser.provider).to eq 'google_oauth2'
    end
  end

  describe '#uid' do
    it 'returns the uid as string' do
      parser = OauthDataParser.new(google_data)
      expect(parser.uid).to eq '12345'
    end
  end

  describe '#user_name' do
    it 'returns first_name for Google' do
      parser = OauthDataParser.new(google_data)
      expect(parser.user_name).to eq 'John'
    end

    it 'returns first part of name for Twitter' do
      parser = OauthDataParser.new(twitter_data)
      expect(parser.user_name).to eq 'Jane'
    end

    it 'returns first_name for Facebook' do
      parser = OauthDataParser.new(facebook_data)
      expect(parser.user_name).to eq 'Alice'
    end
  end

  describe '#user_surname' do
    it 'returns last_name for Google' do
      parser = OauthDataParser.new(google_data)
      expect(parser.user_surname).to eq 'Doe'
    end

    it 'returns second part of name for Twitter' do
      parser = OauthDataParser.new(twitter_data)
      expect(parser.user_surname).to eq 'Smith'
    end

    it 'returns last_name for Facebook' do
      parser = OauthDataParser.new(facebook_data)
      expect(parser.user_surname).to eq 'Wonder'
    end
  end

  describe '#user_email' do
    it 'returns email from raw_info for Google' do
      parser = OauthDataParser.new(google_data)
      expect(parser.user_email).to eq 'user@example.com'
    end

    it 'returns nil email for Twitter' do
      parser = OauthDataParser.new(twitter_data)
      expect(parser.user_email).to be_nil
    end
  end

  describe '#user_sex' do
    it 'returns first letter of gender for Google' do
      parser = OauthDataParser.new(google_data)
      expect(parser.user_sex).to eq 'm'
    end

    it 'returns nil when gender is absent' do
      parser = OauthDataParser.new(twitter_data)
      expect(parser.user_sex).to be_nil
    end
  end

  describe '#user_avatar_url' do
    it 'returns picture for Google' do
      parser = OauthDataParser.new(google_data)
      expect(parser.user_avatar_url).to eq 'https://example.com/photo.jpg'
    end

    it 'returns profile_image_url for Twitter' do
      parser = OauthDataParser.new(twitter_data)
      expect(parser.user_avatar_url).to eq 'https://pbs.twimg.com/profile.jpg'
    end
  end

  describe '#verified?' do
    it 'returns true for Google (non-Facebook)' do
      parser = OauthDataParser.new(google_data)
      expect(parser.verified?).to be true
    end

    it 'returns raw_info verified for Facebook' do
      parser = OauthDataParser.new(facebook_data)
      expect(parser.verified?).to be true
    end

    it 'returns true for Twitter' do
      parser = OauthDataParser.new(twitter_data)
      expect(parser.verified?).to be true
    end
  end

  describe '#user_info' do
    it 'returns a hash with all user fields' do
      parser = OauthDataParser.new(google_data)
      info = parser.user_info
      expect(info).to include(:email, :name, :surname, :sex, :verified, :avatar_url)
      expect(info[:email]).to eq 'user@example.com'
      expect(info[:name]).to eq 'John'
    end
  end
end
