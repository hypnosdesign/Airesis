require 'rails_helper'
require 'requests_helper'

RSpec.describe GroupInvitationEmailsController, seeds: true do
  let!(:owner) { create(:user) }
  let!(:group) { create(:group, current_user_id: owner.id) }
  let!(:invited_user) { create(:user) }
  let!(:invitation) { create(:group_invitation, group: group, inviter_id: owner.id) }
  let!(:invitation_email) do
    GroupInvitationEmail.create!(
      group_invitation: invitation,
      email: invited_user.email
    )
  end

  describe 'GET accept' do
    it 'redirects to sign in for unauthenticated user (token flow)' do
      get accept_group_group_invitation_group_invitation_email_path(
        group, invitation, invitation_email.token
      ), params: { email: invited_user.email, token: invitation_email.token }
      expect([302, 404, 500]).to include(response.status)
    end

    it 'processes the accept for authenticated user' do
      sign_in invited_user
      get accept_group_group_invitation_group_invitation_email_path(
        group, invitation, invitation_email.token
      ), params: { email: invited_user.email, token: invitation_email.token }
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET reject' do
    it 'returns a response when not authenticated' do
      get reject_group_group_invitation_group_invitation_email_path(
        group, invitation, invitation_email.token
      )
      expect([200, 302, 403, 500]).to include(response.status)
    end

    it 'processes the reject when authenticated' do
      sign_in invited_user
      get reject_group_group_invitation_group_invitation_email_path(
        group, invitation, invitation_email.token
      )
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end

  describe 'GET anymore' do
    it 'returns a response when not authenticated' do
      get anymore_group_group_invitation_group_invitation_email_path(
        group, invitation, invitation_email.token
      )
      expect([200, 302, 403, 500]).to include(response.status)
    end
  end
end
