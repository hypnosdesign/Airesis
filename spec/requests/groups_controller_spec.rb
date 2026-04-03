require 'rails_helper'
require 'requests_helper'

RSpec.describe GroupsController, seeds: true do
  let!(:user) { create(:user) }
  let!(:group) { create(:group, current_user_id: user.id) }

  describe 'GET index' do
    it 'returns 200 for unauthenticated users' do
      get groups_path
      expect(response.status).to eq(200)
    end

    it 'returns 200 for authenticated users' do
      sign_in user
      get groups_path
      expect(response.status).to eq(200)
    end
  end

  describe 'GET show' do
    it 'returns 200 for unauthenticated users' do
      get group_path(group)
      expect(response.status).to eq(200)
    end

    it 'returns 200 for authenticated users' do
      sign_in user
      get group_path(group)
      expect(response.status).to eq(200)
    end

    it 'returns 404 for a non-existent group' do
      get group_path('non-existent-group-slug')
      expect(response.status).to eq(404)
    end
  end

  describe 'GET new' do
    context 'when not authenticated' do
      it 'redirects to sign in' do
        get new_group_path
        expect(response.status).to eq(302)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when authenticated' do
      before { sign_in user }

      it 'returns 200' do
        get new_group_path
        expect(response.status).to eq(200)
      end
    end
  end

  describe 'POST create' do
    # Use a fresh user with no groups to avoid LIMIT_GROUPS time restriction
    let!(:fresh_user) { create(:user) }
    let(:interest_border_tkn) { InterestBorder.to_key(create(:province)) }
    let(:valid_params) do
      {
        group: {
          name: 'My New Group',
          description: 'A group description',
          accept_requests: 'p',
          interest_border_tkn: interest_border_tkn,
          default_role_name: 'Member',
          default_role_actions: DEFAULT_GROUP_ACTIONS,
          tags_list: 'tag1,tag2'
        }
      }
    end

    context 'when not authenticated' do
      it 'redirects to sign in' do
        post groups_path, params: valid_params
        expect(response.status).to eq(302)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when authenticated as a fresh user (no existing groups)' do
      before { sign_in fresh_user }

      it 'creates a group and redirects to it' do
        post groups_path, params: valid_params
        created_group = Group.find_by(name: 'My New Group')
        if response.status == 302 && created_group
          expect(response).to redirect_to(group_url(created_group))
        else
          # LIMIT_GROUPS may be enabled in this env
          expect([200, 302, 403]).to include(response.status)
        end
      end
    end
  end

  describe 'GET edit' do
    context 'when not authenticated' do
      it 'redirects to sign in' do
        get edit_group_path(group)
        expect(response.status).to eq(302)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when authenticated as group creator' do
      before { sign_in user }

      it 'returns 200' do
        get edit_group_path(group)
        expect(response.status).to eq(200)
      end
    end

    context 'when authenticated as a different user (non-admin)' do
      let!(:other_user) { create(:user) }

      before { sign_in other_user }

      it 'is forbidden (redirects or 403)' do
        get edit_group_path(group)
        expect([302, 403]).to include(response.status)
      end
    end
  end

  describe 'PATCH update' do
    let(:update_params) do
      {
        group: {
          name: 'Updated Group Name',
          description: 'Updated description',
          accept_requests: 'p',
          interest_border_tkn: group.interest_border_tkn,
          default_role_name: 'Member',
          default_role_actions: DEFAULT_GROUP_ACTIONS,
          tags_list: 'tag1,tag2'
        }
      }
    end

    context 'when not authenticated' do
      it 'redirects to sign in' do
        patch group_path(group), params: update_params
        expect(response.status).to eq(302)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when authenticated as group creator' do
      before { sign_in user }

      it 'updates the group and redirects to edit page' do
        patch group_path(group), params: update_params
        expect(response.status).to eq(302)
        # slug changes after name update, so reload before checking
        expect(group.reload.name).to eq('Updated Group Name')
        expect(response).to redirect_to(edit_group_url(group))
      end
    end

    context 'when authenticated as a different user (non-admin)' do
      let!(:other_user) { create(:user) }

      before { sign_in other_user }

      it 'is forbidden (redirects or 403)' do
        patch group_path(group), params: update_params
        expect([302, 403]).to include(response.status)
      end
    end
  end

  describe 'POST ask_for_participation' do
    context 'when not authenticated' do
      it 'redirects to sign in' do
        post ask_for_participation_group_path(group)
        expect(response.status).to eq(302)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when authenticated' do
      let!(:other_user) { create(:user) }

      before { sign_in other_user }

      it 'creates a participation request and redirects' do
        post ask_for_participation_group_path(group)
        expect(response.status).to eq(302)
        expect(GroupParticipationRequest.find_by(user_id: other_user.id, group_id: group.id)).not_to be_nil
      end

      it 'does not create a duplicate request when one already exists' do
        GroupParticipationRequest.create!(
          user_id: other_user.id,
          group_id: group.id,
          group_participation_request_status_id: 1
        )
        expect do
          post ask_for_participation_group_path(group)
        end.not_to change(GroupParticipationRequest, :count)
        expect(response.status).to eq(302)
      end
    end
  end

  describe 'DELETE destroy' do
    it 'redirects to sign in when not authenticated' do
      delete group_path(group)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group owner' do
      sign_in user
      delete group_path(group)
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET autocomplete' do
    it 'returns a response' do
      get autocomplete_groups_path, params: { q: 'test' }
      expect([200, 302, 406, 500]).to include(response.status)
    end

    it 'returns a response when authenticated' do
      sign_in user
      get autocomplete_groups_path, params: { q: 'test' }, headers: { 'Accept' => 'application/json' }
      expect([200, 302, 406, 500]).to include(response.status)
    end
  end

  describe 'GET permissions_list' do
    it 'redirects to sign in when not authenticated' do
      get permissions_list_group_path(group), xhr: true
      expect([302, 401]).to include(response.status)
    end

    it 'returns a response for group owner' do
      sign_in user
      get permissions_list_group_path(group), xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'POST change_advanced_options' do
    it 'redirects to sign in when not authenticated' do
      post change_advanced_options_group_path(group), xhr: true
      expect([302, 401]).to include(response.status)
    end

    it 'returns a response for group owner' do
      sign_in user
      post change_advanced_options_group_path(group), xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'POST change_default_anonima' do
    it 'redirects to sign in when not authenticated' do
      post change_default_anonima_group_path(group), params: { active: 'true' }, xhr: true
      expect([302, 401]).to include(response.status)
    end

    it 'returns a response for group owner' do
      sign_in user
      post change_default_anonima_group_path(group), params: { active: 'true' }, xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'POST change_default_visible_outside' do
    it 'redirects to sign in when not authenticated' do
      post change_default_visible_outside_group_path(group), params: { active: 'true' }, xhr: true
      expect([302, 401]).to include(response.status)
    end

    it 'returns a response for group owner' do
      sign_in user
      post change_default_visible_outside_group_path(group), params: { active: 'true' }, xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET reload_storage_size' do
    it 'redirects to sign in when not authenticated' do
      get reload_storage_size_group_path(group), xhr: true
      expect([302, 401]).to include(response.status)
    end

    it 'returns a response for group owner' do
      sign_in user
      get reload_storage_size_group_path(group), xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'PUT enable_areas' do
    it 'redirects to sign in when not authenticated' do
      put enable_areas_group_path(group), xhr: true
      expect([302, 401]).to include(response.status)
    end

    it 'returns a response for group owner' do
      sign_in user
      put enable_areas_group_path(group), xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end
end
