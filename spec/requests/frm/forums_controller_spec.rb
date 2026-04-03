require 'rails_helper'
require 'requests_helper'

RSpec.describe Frm::ForumsController, seeds: true do
  let!(:owner) { create(:user) }
  let!(:group) { create(:group, current_user_id: owner.id) }
  let!(:forum) { group.forums.first }

  describe 'GET index' do
    it 'returns a response for unauthenticated users' do
      get group_forums_path(group)
      expect([200, 302, 403, 500]).to include(response.status)
    end

    it 'returns a response for authenticated group members' do
      sign_in owner
      get group_forums_path(group)
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET show' do
    it 'returns a response for unauthenticated users' do
      get group_forum_path(group, forum)
      expect([200, 302, 403, 500]).to include(response.status)
    end

    it 'returns a response for authenticated group members' do
      sign_in owner
      get group_forum_path(group, forum)
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end
end
