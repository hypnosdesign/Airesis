require 'rails_helper'
require 'requests_helper'

RSpec.describe Admin::ModeratorController, seeds: true do
  let!(:moderator) { create(:user, user_type_id: User.user_type_ids[:moderator]) }
  let!(:user) { create(:user) }

  it 'is not routed for guests or regular users' do
    get moderator_panel_path
    expect(response).to have_http_status(:not_found)

    sign_in user
    get moderator_panel_path
    expect(response).to have_http_status(:not_found)
  end

  it 'renders for moderators' do
    sign_in moderator

    get moderator_panel_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t('pages.moderator_panel.title'))
  end
end
