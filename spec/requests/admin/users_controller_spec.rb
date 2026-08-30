require 'rails_helper'
require 'requests_helper'

RSpec.describe Admin::UsersController, seeds: true do
  let!(:admin) { create(:admin) }
  let!(:moderator) { create(:user, user_type_id: User.user_type_ids[:moderator]) }
  let!(:user) { create(:user) }

  it 'does not route account controls for guests' do
    post block_admin_users_path, params: { user_id: user.id }

    expect(response).to have_http_status(:not_found)
  end

  it 'allows a moderator to autocomplete regular users' do
    sign_in moderator

    get autocomplete_admin_users_path, params: { term: user.name }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to be_an(Array)
    expect(response.parsed_body.pluck('id')).to contain_exactly(user.id)
  end

  it 'blocks a regular user by exact email and redirects with 303' do
    sign_in moderator

    post block_admin_users_path, params: { user_id: user.email.upcase }

    expect(response).to have_http_status(:see_other)
    expect(user.reload).to be_blocked
    expect(user.name).to eq('Utente')
    expect(user.blocked_name).to be_present
  end

  it 'returns 404 for a missing target without side effects' do
    sign_in moderator

    expect do
      post block_admin_users_path, params: { user_id: 'no-such-user@example.test' }
    end.not_to change(User.where(blocked: true), :count)

    expect(response).to have_http_status(:not_found)
  end

  it 'protects the current and every privileged account' do
    sign_in admin

    post block_admin_users_path, params: { user_id: admin.id }
    expect(response).to have_http_status(:see_other)
    expect(admin.reload).not_to be_blocked

    post block_admin_users_path, params: { user_id: moderator.id }
    expect(moderator.reload).not_to be_blocked
  end

  it 'does not unblock through GET' do
    user.update!(blocked: true, blocked_name: user.name, blocked_surname: user.surname, name: 'Utente', surname: 'Eliminato')
    sign_in moderator

    get unblock_admin_user_path(user)
    expect(response).to have_http_status(:not_found)
    expect(user.reload).to be_blocked
  end

  it 'restores a blocked account through PATCH' do
    user.update!(blocked: true, blocked_name: user.name, blocked_surname: user.surname, name: 'Utente', surname: 'Eliminato')
    sign_in moderator

    patch unblock_admin_user_path(user)
    expect(response).to have_http_status(:see_other)
    expect(user.reload).not_to be_blocked
    expect(user.name).not_to eq('Utente')
  end
end
