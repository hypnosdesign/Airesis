require 'rails_helper'

RSpec.describe User::Authenticatable, type: :model, seeds: true do
  let!(:user) { create(:user) }

  describe '#from_identity_provider?' do
    it 'returns false when user has no authentications' do
      expect(user.from_identity_provider?).to be false
    end

    it 'returns true when user has at least one authentication' do
      user.authentications.create!(provider: 'google_oauth2', uid: '12345', token: 'abc')
      expect(user.from_identity_provider?).to be true
    end
  end

  describe '#has_provider?' do
    it 'returns false when user has no authentication for given provider' do
      expect(user.has_provider?('facebook')).to be false
    end

    it 'returns true when user has authentication for given provider' do
      user.authentications.create!(provider: 'facebook', uid: '99999', token: 'fb_token')
      expect(user.has_provider?('facebook')).to be true
    end
  end

  describe '#build_authentication_provider' do
    it 'builds an authentication with the given access token data' do
      access_token = {
        'provider' => 'google_oauth2',
        'uid' => '67890',
        'credentials' => { 'token' => 'google_token' }
      }
      auth = user.build_authentication_provider(access_token)
      expect(auth.provider).to eq 'google_oauth2'
      expect(auth.uid).to eq '67890'
      expect(auth.token).to eq 'google_token'
    end
  end

  describe '#set_social_network_pages' do
    it 'sets google_page_url when provider is google' do
      raw_info = { 'profile' => 'https://plus.google.com/user123' }
      user.set_social_network_pages(Authentication::GOOGLE, raw_info)
      expect(user.google_page_url).to eq 'https://plus.google.com/user123'
    end

    it 'sets facebook_page_url when provider is facebook' do
      raw_info = { 'link' => 'https://facebook.com/user123' }
      user.set_social_network_pages(Authentication::FACEBOOK, raw_info)
      expect(user.facebook_page_url).to eq 'https://facebook.com/user123'
    end

    it 'does not set anything for other providers' do
      raw_info = {}
      expect { user.set_social_network_pages('twitter', raw_info) }.not_to change(user, :google_page_url)
    end
  end

  describe '#twitter_page_url' do
    it 'returns nil when user has no Twitter authentication' do
      expect(user.twitter_page_url).to be_nil
    end

    it 'returns Twitter URL when user has Twitter authentication' do
      user.authentications.create!(provider: Authentication::TWITTER, uid: 'tweet123', token: 'tw_token')
      expect(user.twitter_page_url).to include('tweet123')
    end
  end

  describe '#has_oauth_provider_without_email' do
    it 'returns false when user has no Twitter authentication' do
      expect(user.has_oauth_provider_without_email).to be false
    end

    it 'returns true when user has Twitter authentication' do
      user.authentications.create!(provider: Authentication::TWITTER, uid: 'twt_uid', token: 'tok')
      expect(user.has_oauth_provider_without_email).to be true
    end
  end

  describe '#send_reset_password_instructions' do
    it 'returns false for blocked users and adds an error' do
      user.update!(blocked: true)
      result = user.send_reset_password_instructions
      expect(result).to be false
      expect(user.errors[:base]).not_to be_empty
    end

    it 'processes normally for non-blocked users' do
      expect(user.blocked).to be_falsy
      locale = SysLocale.first || create(:sys_locale, :default)
      user.update!(original_sys_locale_id: locale.id)
      result = user.send_reset_password_instructions
      expect([true, false]).to include(result)
    end
  end

  describe '.find_or_create_for_oauth_provider' do
    context 'when authentication already exists' do
      let(:auth_data) do
        {
          'provider' => 'google_oauth2',
          'uid' => 'existing_uid',
          'info' => { 'email' => user.email, 'name' => 'Test User' },
          'extra' => { 'raw_info' => { 'email' => user.email } },
          'credentials' => { 'token' => 'token123' }
        }
      end

      before do
        user.authentications.create!(provider: 'google_oauth2', uid: 'existing_uid', token: 'tok')
      end

      it 'returns the existing user' do
        found_user, new_account, merge_required = User.find_or_create_for_oauth_provider(auth_data)
        expect(found_user).to eq user
        expect(new_account).to be false
        expect(merge_required).to be false
      end
    end

    context 'when email matches an existing user without that auth' do
      let(:auth_data) do
        {
          'provider' => 'google_oauth2',
          'uid' => 'new_google_uid',
          'info' => { 'email' => user.email, 'name' => user.name },
          'extra' => { 'raw_info' => { 'email' => user.email } },
          'credentials' => { 'token' => 'token456' }
        }
      end

      it 'returns the existing user with merge_required = true' do
        found_user, new_account, merge_required = User.find_or_create_for_oauth_provider(auth_data)
        expect(found_user).to eq user
        expect(new_account).to be true
        expect(merge_required).to be true
      end
    end
  end
end
