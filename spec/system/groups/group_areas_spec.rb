require 'rails_helper'
require 'requests_helper'

RSpec.describe 'group area governance', :js, seeds: true do
  let!(:owner) { create(:user) }
  let!(:group) { create(:group, current_user_id: owner.id) }

  before { login_as owner, scope: :user }
  after { logout :user }

  it 'enables work areas from the empty state' do
    visit group_group_areas_path(group)
    click_link I18n.t('pages.groups.edit_work_areas.index.enable')

    expect(page).to have_current_path(group_group_areas_path(group))
    expect(page).to have_css('main#main-content')
    expect(page).to have_content(I18n.t('pages.groups.edit_work_areas.manage.empty_title'))
    expect(group.reload.enable_areas).to be(true)
  end

  it 'creates a work area with a default role' do
    group.update!(enable_areas: true)
    visit new_group_group_area_path(group)

    fill_in I18n.t('activerecord.attributes.group_area.name'), with: 'Accessibility team'
    fill_in I18n.t('activerecord.attributes.group_area.description'), with: 'Reviews inclusive participation.'
    fill_in I18n.t('activerecord.attributes.group_area.default_role_name'), with: 'Contributor'
    click_button I18n.t('buttons.create')

    expect(page).to have_content(I18n.t('info.groups.work_area.area_created'))
    area = group.group_areas.find_by!(name: 'Accessibility team')
    expect(page).to have_current_path(group_group_area_path(group, area))
    expect(page).to have_css('main#main-content')
    expect(page).to have_content('Accessibility team')
    expect(area.default_area_role.name).to eq('Contributor')
  end

  it 'opens a named create dialog from the index' do
    group.update!(enable_areas: true)
    visit group_group_areas_path(group)

    click_link I18n.t('pages.groups.edit_work_areas.manage.new_area')

    expect(page).to have_css('dialog[open][aria-labelledby="group-area-dialog-title"]')
    expect(page).to have_css('#group-area-dialog-title', text: I18n.t('pages.groups.edit_work_areas.form.title'))
    click_button I18n.t('buttons.cancel')
    expect(page).not_to have_css('dialog[open]')
  end

  it 'adds and removes a group member from the area with visible feedback' do
    group.update!(enable_areas: true)
    member = create(:user, name: 'Ada', surname: 'Member')
    create_participation(member, group)
    area = create(:group_area, group: group, name: 'Inclusive design')

    visit group_group_areas_path(group)
    find('summary', text: I18n.t('pages.groups.edit_quorums.participants')).click
    within("#area_#{area.id}_participant_#{member.id}") do
      click_button I18n.t('pages.groups.edit_work_areas.manage.add_participant')
    end

    expect(page).to have_content(I18n.t('info.area_participation.create'))
    expect(area.area_participations.exists?(user: member)).to be(true)

    find('summary', text: I18n.t('pages.groups.edit_quorums.participants')).click
    accept_confirm do
      within("#area_#{area.id}_participant_#{member.id}") do
        click_button I18n.t('pages.groups.edit_work_areas.manage.remove_participant')
      end
    end

    expect(page).to have_content(I18n.t('info.area_participation.destroy'))
    expect(area.area_participations.exists?(user: member)).to be(false)
  end

  it 'persists area permissions only after an explicit save' do
    group.update!(enable_areas: true)
    area = create(:group_area, group: group, name: 'Decision review')
    role = area.default_area_role
    role.update!(view_proposals: false)
    visit edit_group_group_area_path(group, area)

    within("#area_role_#{role.id}") do
      check I18n.t('db.group_actions.view_proposals.description')
      click_button I18n.t('pages.groups.edit_permissions.save_permissions')
    end

    expect(page).to have_content(I18n.t('info.participation_roles.role_updated'))
    expect(role.reload.view_proposals).to be(true)
  end

  it 'assigns a scoped area role to a member with confirmation' do
    group.update!(enable_areas: true)
    member = create(:user, name: 'Ada', surname: 'Member')
    create_participation(member, group)
    area = create(:group_area, group: group, name: 'Decision review')
    coordinator = AreaRole.create!(name: 'Coordinator', description: 'Coordinates reviews.', group_area: area)
    participation = AreaParticipation.create!(group_area: area, area_role: area.default_area_role, user: member)
    visit edit_group_group_area_path(group, area)

    within('#roles_table tr', text: member.fullname) do
      select coordinator.name, from: "area_role_for_#{member.id}"
      click_button I18n.t('buttons.update')
    end

    expect(page).to have_content(I18n.t('info.participation_roles.role_changed'))
    expect(participation.reload.area_role).to eq(coordinator)
  end
end
