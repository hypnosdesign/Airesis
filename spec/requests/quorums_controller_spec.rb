require 'rails_helper'
require 'requests_helper'

RSpec.describe QuorumsController do
  let!(:province) { create(:province) }
  let!(:user) { create(:user) }
  let!(:group) { create(:group, current_user_id: user.id) }
  let(:quorum_params) do
    {
      best_quorum: {
        name: Faker::Lorem.word,
        description: Faker::Lorem.sentence,
        percentage: 0,
        days_m: 1,
        hours_m: 0,
        minutes_m: 0,
        good_score: 50,
        vote_percentage: 0,
        vote_good_score: 50
      }
    }
  end

  it 'requires authentication for group quorum administration' do
    get group_quorums_path(group)
    expect(response).to redirect_to(new_user_session_path)
  end

  it 'renders the quorum index for the group owner' do
    sign_in user
    get group_quorums_path(group)
    expect(response).to have_http_status(:ok)
  end

  it 'renders the new quorum form in HTML and Turbo Stream' do
    sign_in user
    get new_group_best_quorum_path(group)
    expect(response).to have_http_status(:ok)

    get new_group_best_quorum_path(group), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq('text/vnd.turbo-stream.html')
  end

  it 'creates a quorum in HTML and Turbo Stream' do
    sign_in user
    post group_best_quorums_path(group), params: quorum_params
    expect(response).to redirect_to(group_quorums_path(group))

    expect do
      post group_best_quorums_path(group), params: quorum_params,
           headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    end.to change(BestQuorum, :count).by(1)
    expect(response).to have_http_status(:ok)
  end

  it 'returns 422 for invalid quorum creation' do
    sign_in user
    post group_best_quorums_path(group), params: { best_quorum: quorum_params[:best_quorum].merge(name: '', good_score: nil) },
         headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'updates, activates, deactivates and destroys a quorum for the owner' do
    quorum = create(:best_quorum, group: group)
    sign_in user

    put group_best_quorum_path(group, quorum), params: { best_quorum: quorum_params[:best_quorum].merge(name: 'Updated') }
    expect(response).to redirect_to(group_quorums_path(group))
    expect(quorum.reload.name).to eq('Updated')

    post change_status_group_quorum_path(group, quorum), params: { active: 'true' }
    expect(response).to redirect_to(group_quorums_path(group))
    expect(quorum.reload).to be_active

    post change_status_group_quorum_path(group, quorum), params: { active: 'false' }
    expect(quorum.reload).not_to be_active

    expect do
      delete group_best_quorum_path(group, quorum), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    end.to change(BestQuorum, :count).by(-1)
    expect(response).to have_http_status(:ok)
  end

  it 'renders help after authentication, with and without a group' do
    sign_in user
    get help_quorums_path
    expect(response).to have_http_status(:ok)

    get help_quorums_path, params: { group_id: group.id }
    expect(response).to have_http_status(:ok)
  end

  it 'does not expose legacy quorum routes' do
    expect { Rails.application.routes.recognize_path('/quorums/dates', method: :get) }.to raise_error(ActionController::RoutingError)
    expect(Rails.application.routes.recognize_path('/best_quorums', method: :get)[:controller]).not_to eq('quorums')
    expect(Rails.application.routes.recognize_path('/old_quorums', method: :get)[:controller]).not_to eq('quorums')
  end
end
