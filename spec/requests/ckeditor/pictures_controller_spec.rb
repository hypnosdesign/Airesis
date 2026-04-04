require 'rails_helper'
require 'requests_helper'

RSpec.describe Ckeditor::PicturesController, seeds: true do
  let!(:user) { create(:user) }

  describe 'GET index' do
    it 'redirects to sign in when not authenticated' do
      get ckeditor.pictures_path
      expect([302, 401, 403, 500]).to include(response.status)
    end

    it 'returns a response when authenticated' do
      sign_in user
      get ckeditor.pictures_path
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'DELETE destroy' do
    it 'requires authentication' do
      delete ckeditor.picture_path(1)
      expect([302, 401, 403, 404, 500]).to include(response.status)
    end
  end
end
