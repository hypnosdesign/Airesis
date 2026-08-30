require 'rails_helper'
require 'requests_helper'

RSpec.describe Frm::Admin::MembersController, seeds: true do
  let!(:owner) { create(:user) }
  let!(:member) { create(:user) }
  let!(:group) { create(:group, current_user_id: owner.id) }
  let!(:mod) { Frm::Mod.create!(name: 'Moderators', group: group) }

  describe 'POST add' do
    it 'redirects unauthenticated users to sign in' do
      post add_group_frm_admin_mod_members_path(group, mod), params: { frm_user_id: member.id }

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'adds a member to the scoped moderation team' do
      sign_in owner

      expect do
        post add_group_frm_admin_mod_members_path(group, mod), params: { frm_user_id: member.id }
      end.to change { mod.members.where(id: member.id).count }.by(1)

      expect(response).to redirect_to(group_frm_admin_mod_url(group, mod))
      expect(response).to have_http_status(:see_other)
    end

    it 'does not duplicate an existing member' do
      mod.members << member
      sign_in owner

      expect do
        post add_group_frm_admin_mod_members_path(group, mod), params: { frm_user_id: member.id }
      end.not_to(change { mod.members.where(id: member.id).count })

      expect(response).to have_http_status(:see_other)
    end

    it 'handles a missing user without changing memberships' do
      sign_in owner

      expect do
        post add_group_frm_admin_mod_members_path(group, mod), params: { frm_user_id: 0 }
      end.not_to change(Frm::Membership, :count)

      expect(response).to have_http_status(:see_other)
    end

    it 'cannot mutate a moderation team from another group' do
      other_owner = create(:user)
      other_group = create(:group, current_user_id: other_owner.id)
      other_mod = Frm::Mod.create!(name: 'Other moderators', group: other_group)
      sign_in owner

      expect do
        post add_group_frm_admin_mod_members_path(group, other_mod), params: { frm_user_id: member.id }
      end.not_to(change { other_mod.members.where(id: member.id).count })

      expect(response).to have_http_status(:not_found)
    end
  end
end
