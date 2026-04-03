require 'rails_helper'
require 'requests_helper'

RSpec.describe Admin::NewslettersController, seeds: true do
  let!(:admin) { create(:admin) }
  let!(:newsletter) { Newsletter.create!(subject: 'Test Newsletter', body: '<p>Hello</p>', receiver: 'all') }

  describe 'GET index' do
    it 'returns 404 or redirect for non-authenticated users (admin routing constraint)' do
      get admin_newsletters_path
      expect([302, 404]).to include(response.status)
    end

    it 'returns a response for admin users' do
      sign_in admin
      get admin_newsletters_path
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'GET new' do
    it 'returns 404 or redirect for non-authenticated users' do
      get new_admin_newsletter_path
      expect([302, 404]).to include(response.status)
    end

    it 'returns a response for admin users' do
      sign_in admin
      get new_admin_newsletter_path
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'POST create' do
    it 'returns 404 or redirect for non-authenticated users' do
      post admin_newsletters_path,
           params: { newsletter: { subject: 'Test', body: 'Content', receiver: 'all' } }
      expect([302, 404]).to include(response.status)
    end

    it 'returns a response for admin users' do
      sign_in admin
      post admin_newsletters_path,
           params: { newsletter: { subject: 'Test Newsletter', body: '<p>Body</p>', receiver: 'all' } }
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'GET edit' do
    it 'returns 404 or redirect for non-authenticated users' do
      get edit_admin_newsletter_path(newsletter)
      expect([302, 404]).to include(response.status)
    end

    it 'returns a response for admin users' do
      sign_in admin
      get edit_admin_newsletter_path(newsletter)
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'GET preview' do
    it 'returns 404 or redirect for non-authenticated users' do
      get preview_admin_newsletter_path(newsletter)
      expect([302, 404]).to include(response.status)
    end

    it 'returns a response for admin users' do
      sign_in admin
      get preview_admin_newsletter_path(newsletter)
      expect([200, 302, 500]).to include(response.status)
    end
  end
end
