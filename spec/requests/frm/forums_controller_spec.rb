require 'rails_helper'
require 'requests_helper'

RSpec.describe Frm::ForumsController, seeds: true do
  let!(:owner) { create(:user) }
  let!(:group) { create(:group, current_user_id: owner.id) }
  let!(:category) { create(:frm_category, group: group, visible_outside: true) }
  let!(:forum) { create(:frm_forum, category: category, group: group, visible_outside: true) }

  describe 'GET index' do
    it 'returns a response for unauthenticated users' do
      get group_forums_path(group)
      expect(response).to have_http_status(:ok)
    end

    it 'returns a response for authenticated group members' do
      sign_in owner
      get group_forums_path(group)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET show' do
    it 'returns a response for unauthenticated users' do
      get group_forum_path(group, forum)
      expect(response).to have_http_status(:ok)
    end

    it 'returns a response for authenticated group members' do
      sign_in owner
      get group_forum_path(group, forum)
      expect(response).to have_http_status(:ok)
    end
  end
end
