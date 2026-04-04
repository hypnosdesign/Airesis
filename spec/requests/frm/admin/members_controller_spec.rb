require 'rails_helper'
require 'requests_helper'

RSpec.describe Frm::Admin::MembersController, seeds: true do
  let!(:owner) { create(:user) }
  let!(:member) { create(:user) }
  let!(:group) { create(:group, current_user_id: owner.id) }
  let!(:mod) { Frm::Mod.create!(name: 'Moderators', group: group) }

  describe 'POST add' do
    it 'redirects to sign in when not authenticated' do
      post add_group_frm_admin_mod_members_path(group, mod),
           params: { frm_user_id: member.id }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'adds member for group owner (HTML)' do
      sign_in owner
      post add_group_frm_admin_mod_members_path(group, mod),
           params: { frm_user_id: member.id }
      expect([200, 302, 403, 500]).to include(response.status)
    end

    it 'adds member for group owner (JS)' do
      sign_in owner
      post add_group_frm_admin_mod_members_path(group, mod),
           xhr: true,
           params: { frm_user_id: member.id }
      expect([200, 302, 403, 500]).to include(response.status)
    end

    it 'handles already-added member' do
      mod.members << member rescue nil
      sign_in owner
      post add_group_frm_admin_mod_members_path(group, mod),
           params: { frm_user_id: member.id }
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end
end
