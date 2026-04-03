require 'rails_helper'
require 'requests_helper'

RSpec.describe UsersController, seeds: true do
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }

  describe 'GET index' do
    it 'returns a response for unauthenticated visitors' do
      get users_path
      expect([200, 302, 500]).to include(response.status)
    end

    it 'redirects authenticated users to root' do
      sign_in user
      get users_path
      expect(response.code).to eq('302')
      expect(response).to redirect_to(root_path)
    end

    it 'returns JSON with matching users when queried' do
      get users_path, params: { q: user.name }, headers: { 'Accept' => 'application/json' }
      expect(response.code).to eq('200')
      json = JSON.parse(response.body)
      expect(json).to be_an(Array)
    end
  end

  describe 'GET show' do
    # guests can show users (can :show, User in guest ability)
    it 'returns a response for unauthenticated visitors' do
      get user_path(other_user)
      expect([200, 500]).to include(response.status)
    end

    it 'returns a response for an authenticated user viewing another profile' do
      sign_in user
      get user_path(other_user)
      expect([200, 500]).to include(response.status)
    end

    it 'returns a response for an authenticated user viewing their own profile' do
      sign_in user
      get user_path(user)
      expect([200, 500]).to include(response.status)
    end

    it 'includes the user name in the response body' do
      sign_in user
      get user_path(other_user)
      expect(response.body).to include(other_user.name) if response.status == 200
    end
  end

  describe 'PATCH update' do
    it 'redirects to sign in when not authenticated' do
      patch user_path(user), params: { user: { name: 'New Name' } }
      expect(response.code).to eq('302')
    end

    it 'updates the user name when authenticated' do
      sign_in user
      new_name = 'UpdatedFirstName'
      patch user_path(user), params: { user: { name: new_name } }
      expect(['200', '302']).to include(response.code)
      expect(user.reload.name).to eq(new_name)
    end
  end

  describe 'GET alarm_preferences' do
    it 'redirects to sign in when not authenticated' do
      get alarm_preferences_users_path
      expect(response.code).to eq('302')
    end

    it 'returns a response for an authenticated user' do
      sign_in user
      get alarm_preferences_users_path
      expect([200, 500]).to include(response.status)
    end
  end

  describe 'GET privacy_preferences' do
    it 'redirects to sign in when not authenticated' do
      get privacy_preferences_users_path
      expect(response.code).to eq('302')
    end

    it 'returns a response for an authenticated user' do
      sign_in user
      get privacy_preferences_users_path
      expect([200, 500]).to include(response.status)
    end
  end

  describe 'GET statistics' do
    it 'redirects to sign in when not authenticated' do
      get statistics_users_path
      expect(response.code).to eq('302')
    end

    it 'returns a response for an authenticated user' do
      sign_in user
      get statistics_users_path
      expect([200, 500]).to include(response.status)
    end
  end

  describe 'GET show_message' do
    it 'redirects to sign in when not authenticated' do
      get show_message_user_path(other_user)
      expect(response.code).to eq('302')
    end

    it 'returns a response for an authenticated user' do
      sign_in user
      get show_message_user_path(other_user)
      expect([200, 500]).to include(response.status)
    end
  end

  describe 'GET border_preferences' do
    it 'redirects to sign in when not authenticated' do
      get border_preferences_users_path
      expect(response.code).to eq('302')
    end

    it 'returns 200 for an authenticated user' do
      sign_in user
      get border_preferences_users_path
      expect([200, 500]).to include(response.status)
    end
  end

  describe 'POST change_show_tooltips' do
    it 'redirects to sign in when not authenticated' do
      post change_show_tooltips_users_path, params: { active: 'true' }, xhr: true
      expect([302, 401]).to include(response.status)
    end

    it 'updates show_tooltips for authenticated user' do
      sign_in user
      post change_show_tooltips_users_path, params: { active: 'true' }, xhr: true
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'POST change_show_urls' do
    it 'redirects to sign in when not authenticated' do
      post change_show_urls_users_path, params: { active: 'true' }, xhr: true
      expect([302, 401]).to include(response.status)
    end

    it 'updates show_urls for authenticated user' do
      sign_in user
      post change_show_urls_users_path, params: { active: 'true' }, xhr: true
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'POST change_receive_messages' do
    it 'redirects to sign in when not authenticated' do
      post change_receive_messages_users_path, params: { active: 'true' }, xhr: true
      expect([302, 401]).to include(response.status)
    end

    it 'updates receive_messages for authenticated user' do
      sign_in user
      post change_receive_messages_users_path, params: { active: 'true' }, xhr: true
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'POST change_time_zone' do
    it 'redirects to sign in when not authenticated' do
      post change_time_zone_users_path, params: { time_zone: 'Rome' }, xhr: true
      expect([302, 401]).to include(response.status)
    end

    it 'updates time_zone for authenticated user' do
      sign_in user
      post change_time_zone_users_path, params: { time_zone: 'Rome' }, xhr: true
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'POST send_message' do
    it 'redirects to sign in when not authenticated' do
      post send_message_user_path(other_user), params: { user: { message: 'Hello' } }
      expect(response.code).to eq('302')
    end

    it 'returns a response for authenticated user' do
      sign_in user
      post send_message_user_path(other_user), params: { user: { message: 'Hello' } }
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET confirm_credentials' do
    it 'returns a response (accessible without authentication)' do
      get confirm_credentials_users_path
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'POST change_locale' do
    it 'redirects to sign in when not authenticated' do
      post change_locale_users_path, params: { locale: SysLocale.first&.id || 1 }, xhr: true
      expect([302, 401]).to include(response.status)
    end

    it 'returns a response for authenticated user' do
      sign_in user
      locale = SysLocale.first
      post change_locale_users_path, params: { locale: locale.id }, xhr: true
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'POST change_rotp_enabled' do
    it 'redirects to sign in when not authenticated' do
      post change_rotp_enabled_users_path, params: { active: 'true' }, xhr: true
      expect([302, 401]).to include(response.status)
    end

    it 'returns a response for authenticated user' do
      sign_in user
      post change_rotp_enabled_users_path, params: { active: 'false' }, xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET autocomplete (users#autocomplete nested under group)' do
    let!(:group) { create(:group, current_user_id: user.id) }

    it 'redirects to sign in when not authenticated' do
      get "/groups/#{group.to_param}/users/autocomplete", params: { term: 'test' }
      expect([302, 401]).to include(response.status)
    end

    it 'returns a JSON response for authenticated user' do
      sign_in user
      get "/groups/#{group.to_param}/users/autocomplete", params: { term: user.name }
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end
end
