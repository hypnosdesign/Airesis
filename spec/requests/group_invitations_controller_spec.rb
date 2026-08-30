require 'rails_helper'
require 'requests_helper'

RSpec.describe GroupInvitationsController, seeds: true do
  let!(:owner) { create(:user) }
  let!(:group) { create(:group, current_user_id: owner.id) }

  describe 'GET new' do
    it 'redirects to sign in when not authenticated' do
      get new_group_group_invitation_path(group)
      expect([302, 403]).to include(response.status)
    end

    it 'renders a contextual invitation form for the group owner' do
      sign_in owner
      get new_group_group_invitation_path(group)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<main')
      expect(response.body).to include('<h1')
      expect(response.body).to safe_include(group.name)
      expect(response.body).to safe_include(I18n.t('pages.groups.invite_your_friends.type_email_addresses'))
    end

    it 'is forbidden for non-members' do
      outsider = create(:user)
      sign_in outsider
      get new_group_group_invitation_path(group)
      expect([302, 403]).to include(response.status)
    end
  end

  describe 'POST create' do
    before { sign_in owner }

    it 'renders validation errors for an empty recipient list' do
      expect do
        post group_group_invitations_path(group), params: { group_invitation: { emails_list: '', testo: 'Ciao' } }
      end.not_to change(GroupInvitation, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('<h1')
    end

    it 'replaces the standalone form with validation errors for Turbo requests' do
      expect do
        post group_group_invitations_path(group),
             params: { group_invitation: { emails_list: 'not-an-email', testo: 'Ciao' } },
             headers: { 'ACCEPT' => 'text/vnd.turbo-stream.html' }
      end.not_to change(GroupInvitation, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(response.body).to include('target="group_invitation_form"')
      expect(response.body).to safe_include(GroupInvitation.human_attribute_name(:emails_list))
    end

    it 'creates invitations for normalized valid addresses' do
      expect do
        post group_group_invitations_path(group), params: {
          group_invitation: { emails_list: " ONE@example.org; two@example.org\ninvalid ", testo: 'Ciao' }
        }
      end.to change(GroupInvitation, :count).by(1)

      expect(response).to redirect_to(group_path(group))
      expect(GroupInvitation.last.group_invitation_emails.pluck(:email)).to contain_exactly('one@example.org', 'two@example.org')
    end
  end
end
