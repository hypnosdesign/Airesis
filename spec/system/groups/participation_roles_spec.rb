require 'rails_helper'
require 'requests_helper'

RSpec.describe 'group role governance', :js, seeds: true do
  let!(:owner) { create(:user) }
  let!(:group) { create(:group, current_user_id: owner.id) }

  after { logout :user }

  it 'requires authentication' do
    visit group_participation_roles_path(group)
    expect_sign_in_page
  end

  context 'as group owner' do
    before { login_as owner, scope: :user }

    it 'shows one named permission form per role and protects the default' do
      visit group_participation_roles_path(group)

      expect(page).to have_css('main#main-content')
      expect(page).to have_css("#role_#{group.default_participation_role.id}")
      expect(page).to have_content(I18n.t('pages.groups.edit_permissions.default_protected'))
      expect(page).to have_button(I18n.t('pages.groups.edit_permissions.save_permissions'))
      expect(page).not_to have_css("#role_#{group.default_participation_role.id} a", text: I18n.t('buttons.delete'))

      duplicate_ids = page.all('[id]', visible: :all).map { |node| node[:id] }.tally.select { |_id, count| count > 1 }
      expect(duplicate_ids).to be_empty
    end

    it 'persists a permission only after an explicit save' do
      role = group.default_participation_role
      role.update!(write_to_wall: false)
      visit group_participation_roles_path(group)

      within("#role_#{role.id}") do
        check I18n.t('db.group_actions.write_to_wall.description')
        click_button I18n.t('pages.groups.edit_permissions.save_permissions')
      end

      expect(page).to have_content(I18n.t('info.participation_roles.role_updated'))
      expect(role.reload.write_to_wall).to be(true)
    end

    it 'creates a role on a focused page' do
      visit new_group_participation_role_path(group)
      fill_in I18n.t('activerecord.attributes.participation_role.name'), with: 'Facilitator'
      fill_in I18n.t('activerecord.attributes.participation_role.description'), with: 'Facilitates group decisions.'
      click_button I18n.t('buttons.create')

      expect(page).to have_current_path(group_participation_roles_path(group))
      expect(page).to have_content('Facilitator')
      expect(group.participation_roles.exists?(name: 'Facilitator')).to be(true)
    end
  end
end
