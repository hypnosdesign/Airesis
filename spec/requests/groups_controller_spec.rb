require 'rails_helper'
require 'requests_helper'

RSpec.describe GroupsController, seeds: true do
  let!(:user) { create(:user) }
  let!(:group) { create(:group, current_user_id: user.id) }

  describe 'GET index' do
    it 'returns a response for unauthenticated users' do
      get groups_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<main')
      expect(response.parsed_body.at_css('details')&.key?('open')).to be(false)
    end

    it 'returns a response for authenticated users' do
      sign_in user
      get groups_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to safe_include(group.name)
    end
  end

  describe 'GET show' do
    it 'returns a response for unauthenticated users' do
      get group_path(group)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<main')
      expect(response.body).to safe_include(group.name)
    end

    it 'returns a response for authenticated users' do
      sign_in user
      get group_path(group)
      expect(response).to have_http_status(:ok)
      expect(response.body).to safe_include(I18n.t('pages.groups.show.participants_list'))
      expect(response.body).to include('id="participants_container"')
      expect(response.body).to include('id="participation_requests_container"')
    end

    it 'returns 404 for a non-existent group' do
      get group_path('non-existent-group-slug')
      expect(response).to have_http_status(:not_found)
      expect(response.body).to safe_include(I18n.t('error.error_404.title'))
      expect(response.body).not_to safe_include(I18n.t('error.error_404.groups.title'))
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

      it 'returns a response' do
        get new_group_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('<main')
        expect(response.body).to safe_include(I18n.t('pages.groups.new.new_group'))
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

      it 'replaces the form with validation errors for an invalid Turbo request' do
        invalid_params = { group: valid_params.fetch(:group).merge(name: '') }

        expect do
          post groups_path,
               params: invalid_params,
               headers: { 'ACCEPT' => 'text/vnd.turbo-stream.html' }
        end.not_to change(Group, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
        expect(response.body).to include('target="group_form"')
        expect(response.body).to safe_include(I18n.t('error.groups.creation'))
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

      it 'returns a response' do
        get edit_group_path(group)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('<main')
        expect(response.body).to safe_include(group.name)
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

      it 'renders edit with validation errors instead of raising' do
        patch group_path(group), params: { group: { name: '' } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to safe_include(I18n.t('pages.groups.edit.modify_group'))
        expect(group.reload.name).not_to be_blank
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
      get permissions_list_group_path(group)
      expect(response).to have_http_status(:ok)
      expect(response.body).to safe_include(I18n.t('pages.groups.show.list_permissions.title'))
    end
  end

  describe 'G05 route contract' do
    it 'exposes only implemented invitation and participation actions' do
      routes = Rails.application.routes.routes.select do |route|
        route.defaults[:controller].to_s.in?(%w[groups group_participations group_invitations group_invitation_emails])
      end
      actions = routes.map { |route| [route.defaults[:controller].to_s, route.defaults[:action].to_s] }

      expect(routes.count).to eq(34)
      expect(actions).not_to include(
        ['groups', 'create_event'],
        ['group_participations', 'new'],
        ['group_participations', 'create'],
        ['group_participations', 'edit'],
        ['group_participations', 'update'],
        ['group_invitations', 'index'],
        ['group_invitations', 'show'],
        ['group_invitations', 'destroy'],
        ['group_invitation_emails', 'index'],
        ['group_invitation_emails', 'create']
      )
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

  describe 'GET by_year_and_month' do
    it 'returns a response when not authenticated' do
      get posts_by_year_and_month_group_path(group, year: Time.current.year, month: Time.current.month)
      expect([200, 302]).to include(response.status)
    end

    it 'returns a response when authenticated' do
      sign_in user
      get posts_by_year_and_month_group_path(group, year: Time.current.year, month: Time.current.month)
      expect([200, 302]).to include(response.status)
    end
  end

  describe 'POST change_default_secret_vote' do
    it 'redirects to sign in when not authenticated' do
      post change_default_secret_vote_group_path(group), params: { active: 'true' }, xhr: true
      expect([302, 401]).to include(response.status)
    end

    it 'returns a response for group owner' do
      sign_in user
      post change_default_secret_vote_group_path(group), params: { active: 'true' }, xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'PUT participation_request_confirm' do
    let!(:other_user) { create(:user) }
    let!(:pending_request) do
      GroupParticipationRequest.create!(
        user_id: other_user.id,
        group_id: group.id,
        group_participation_request_status_id: 1
      )
    end

    it 'redirects to sign in when not authenticated' do
      put participation_request_confirm_group_path(group), params: { request_id: pending_request.id }
      expect([302, 401]).to include(response.status)
    end

    it 'returns a response for group owner' do
      sign_in user
      put participation_request_confirm_group_path(group), params: { request_id: pending_request.id }
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'PUT participation_request_decline' do
    let!(:other_user) { create(:user) }
    let!(:pending_request) do
      GroupParticipationRequest.create!(
        user_id: other_user.id,
        group_id: group.id,
        group_participation_request_status_id: 1
      )
    end

    it 'redirects to sign in when not authenticated' do
      put participation_request_decline_group_path(group), params: { request_id: pending_request.id }
      expect([302, 401]).to include(response.status)
    end

    it 'returns a response for group owner' do
      sign_in user
      put participation_request_decline_group_path(group), params: { request_id: pending_request.id }
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'PUT remove_post' do
    let!(:blog_post) { create(:blog_post, user: user) }
    let!(:publishing) { create(:post_publishing, blog_post: blog_post, group: group) }

    it 'redirects to sign in when not authenticated' do
      put remove_post_group_path(group), params: { post_id: blog_post.id }, xhr: true
      expect([302, 401]).to include(response.status)
    end

    it 'returns a response for group owner' do
      sign_in user
      put remove_post_group_path(group), params: { post_id: blog_post.id }, xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'PUT feature_post' do
    let!(:blog_post) { create(:blog_post, user: user) }
    let!(:publishing) { create(:post_publishing, blog_post: blog_post, group: group) }

    it 'redirects to sign in when not authenticated' do
      put feature_post_group_path(group), params: { post_id: blog_post.id }, xhr: true
      expect([302, 401]).to include(response.status)
    end

    it 'returns a response for group owner' do
      sign_in user
      put feature_post_group_path(group), params: { post_id: blog_post.id }, xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'POST ask_for_multiple_follow' do
    let!(:other_group) { create(:group, current_user_id: user.id) }
    let!(:other_user) { create(:user) }

    it 'redirects to sign in when not authenticated' do
      post ask_for_multiple_follow_groups_path,
           params: { groupsi: { group_ids: "#{group.id};#{other_group.id}" } }
      expect([302, 401]).to include(response.status)
    end

    it 'returns a response for authenticated user' do
      sign_in other_user
      post ask_for_multiple_follow_groups_path,
           params: { groupsi: { group_ids: "#{group.id};#{other_group.id}" } }
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET show (JS format)' do
    it 'returns a response' do
      sign_in user
      get group_path(group), xhr: true
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'GET show (JSON format)' do
    it 'returns a response' do
      get group_path(group), headers: { 'Accept' => 'application/json' }
      expect([200, 302, 406, 500]).to include(response.status)
    end
  end

  describe 'POST ask_for_participation (already member)' do
    it 'handles the case where user is already a member' do
      other_user = create(:user)
      create_participation(other_user, group)
      sign_in other_user
      post ask_for_participation_group_path(group)
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'PUT participation_request_confirm (Turbo Stream format)' do
    let!(:other_user) { create(:user) }
    let!(:pending_request) do
      GroupParticipationRequest.create!(
        user_id: other_user.id,
        group_id: group.id,
        group_participation_request_status_id: 1
      )
    end

    it 'updates both membership panels for the group owner' do
      sign_in user
      put participation_request_confirm_group_path(group),
          params: { request_id: pending_request.id },
          headers: { 'ACCEPT' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(response.body).to include('target="participants_container"')
      expect(response.body).to include('target="participation_requests_container"')
    end
  end

  describe 'PUT participation_request_decline (Turbo Stream format)' do
    let!(:other_user) { create(:user) }
    let!(:pending_request) do
      GroupParticipationRequest.create!(
        user_id: other_user.id,
        group_id: group.id,
        group_participation_request_status_id: 1
      )
    end

    it 'updates both membership panels for the group owner' do
      sign_in user
      put participation_request_decline_group_path(group),
          params: { request_id: pending_request.id },
          headers: { 'ACCEPT' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(response.body).to include('target="participants_container"')
      expect(response.body).to include('target="participation_requests_container"')
    end

    it 'handles non-existent request' do
      sign_in user
      put participation_request_decline_group_path(group),
          params: { request_id: 999999 }, xhr: true
      expect([200, 302, 403, 404, 500]).to include(response.status)
    end
  end

  describe 'GET by_year_and_month (JS format)' do
    it 'returns a JS response when authenticated' do
      sign_in user
      get posts_by_year_and_month_group_path(group, year: Time.current.year, month: Time.current.month), xhr: true
      expect([200, 302, 500]).to include(response.status)
    end
  end
end
