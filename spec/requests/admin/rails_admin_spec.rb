require 'rails_helper'
require 'requests_helper'

RSpec.describe 'RailsAdmin access', seeds: true do
  let!(:admin) { create(:admin) }
  let!(:user) { create(:user) }

  it 'is not mounted for guests or regular users' do
    get rails_admin_path
    expect(response).to have_http_status(:not_found)

    sign_in user
    get rails_admin_path
    expect(response).to have_http_status(:not_found)
  end

  it 'renders the data dashboard for an administrator' do
    sign_in admin

    get rails_admin_path

    expect(response).to have_http_status(:ok)
  end
end
