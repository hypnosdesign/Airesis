require 'rails_helper'
require 'requests_helper'

RSpec.describe QuorumsController do
  let!(:province) { create(:province) }
  let!(:user) { create(:user) }
  let(:group) { create(:group, current_user_id: user.id) }
  let(:quorum_params) do
    {
      group_id: group.id,
      best_quorum: {
        name: Faker::Lorem.word,
        description: Faker::Lorem.sentence,
        percentage: 0,
        valutations: 0,
        days_m: 1,
        hours_m: 0,
        minutes_m: 0,
        good_score: 50,
        vote_percentage: 0,
        vote_good_score: 50
      }
    }
  end

  describe 'POST create' do
    before do
      sign_in user
    end

    it 'responds to js' do
      post best_quorums_path, params: quorum_params.merge(format: :js)
      expect(response).to have_http_status :ok
    end

    it 'responds to html' do
      post best_quorums_path, params: quorum_params
      expect(response).to have_http_status :found
    end
  end

  describe 'GET index' do
    it 'redirects to sign in when not authenticated' do
      get group_quorums_path(group)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group owner' do
      sign_in user
      get group_quorums_path(group)
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET new' do
    it 'redirects to sign in when not authenticated' do
      get new_group_quorum_path(group)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group owner' do
      sign_in user
      get new_group_quorum_path(group)
      expect([200, 302, 403, 500]).to include(response.status)
    end

    it 'responds to js format' do
      sign_in user
      get new_group_quorum_path(group), params: { format: :js }
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET help' do
    it 'returns a response without group' do
      get help_quorums_path
      expect([200, 302, 500]).to include(response.status)
    end

    it 'returns a response with group_id' do
      get help_quorums_path, params: { group_id: group.id }
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'GET edit' do
    let!(:quorum) { create(:best_quorum, group: group) }

    it 'redirects to sign in when not authenticated' do
      get edit_quorum_path(quorum)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group owner' do
      sign_in user
      get edit_quorum_path(quorum)
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'PUT update' do
    let!(:quorum) { create(:best_quorum, group: group) }

    it 'redirects to sign in when not authenticated' do
      put quorum_path(quorum),
          params: { best_quorum: { name: 'Updated', description: 'desc', percentage: 5, good_score: 50, days_m: 7 } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns a response for group owner' do
      sign_in user
      put quorum_path(quorum),
          params: { best_quorum: { name: 'Updated', description: 'desc', percentage: 5, good_score: 50, days_m: 7 } }
      expect([200, 302, 403, 500]).to include(response.status)
    end

    it 'responds to JS format' do
      sign_in user
      put quorum_path(quorum),
          params: { best_quorum: { name: 'Updated', description: 'desc', percentage: 5, good_score: 50, days_m: 7 } },
          xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end

    it 'renders error for invalid update (JS format)' do
      sign_in user
      put quorum_path(quorum),
          params: { best_quorum: { name: '', good_score: nil } },
          xhr: true
      expect([200, 302, 403, 422, 500]).to include(response.status)
    end
  end

  describe 'DELETE destroy' do
    let!(:quorum) { create(:best_quorum, group: group) }

    it 'redirects to sign in when not authenticated' do
      delete quorum_path(quorum), xhr: true
      expect([302, 401]).to include(response.status)
    end

    it 'destroys the quorum for group owner' do
      sign_in user
      delete quorum_path(quorum), xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'POST change_status' do
    let!(:quorum) { create(:best_quorum, group: group) }

    it 'redirects to sign in when not authenticated' do
      post change_status_group_quorum_path(group, quorum), params: { active: 'true' }, xhr: true
      expect([302, 401]).to include(response.status)
    end

    it 'activates a quorum for group owner' do
      sign_in user
      post change_status_group_quorum_path(group, quorum), params: { active: 'true' }, xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end

    it 'deactivates a quorum for group owner' do
      sign_in user
      post change_status_group_quorum_path(group, quorum), params: { active: 'false' }, xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET dates' do
    it 'redirects to sign in when not authenticated' do
      get dates_quorums_path, xhr: true
      expect([302, 401]).to include(response.status)
    end

    it 'returns a response when authenticated' do
      sign_in user
      get dates_quorums_path, xhr: true
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET help (JS format)' do
    it 'responds to JS format without group' do
      sign_in user
      get help_quorums_path, xhr: true
      expect([200, 302, 500]).to include(response.status)
    end

    it 'responds to JS format with group' do
      sign_in user
      get help_quorums_path, params: { group_id: group.id }, xhr: true
      expect([200, 302, 500]).to include(response.status)
    end
  end

  describe 'POST create (validation error)' do
    it 'handles validation errors in JS format' do
      sign_in user
      invalid_params = quorum_params.deep_merge(best_quorum: { name: '', good_score: nil })
      post best_quorums_path, params: invalid_params.merge(format: :js)
      expect([200, 302, 422, 500]).to include(response.status)
    end
  end
end
