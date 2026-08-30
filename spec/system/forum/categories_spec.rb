require 'rails_helper'
require 'requests_helper'

RSpec.describe 'forum category administration', :js do
  let(:owner) { create(:user) }
  let(:group) { create(:group, current_user_id: owner.id) }

  before do
    load_database
    login_as owner, scope: :user
  end

  it 'renders the administration list without a template error' do
    category = create(:frm_category, group: group, name: 'Working groups')

    visit group_frm_admin_categories_path(group)

    expect(page).to have_selector('h1', text: I18n.t('frm.admin.category.index'))
    expect(page).to have_content(category.name)
    expect(page).not_to have_content(I18n.t('error.error_500.title'))
  end

  it 'creates a category with a clear success state' do
    visit group_frm_admin_categories_path(group)
    click_link I18n.t('frm.admin.category.new_link')

    fill_in I18n.t('simple_form.labels.frm_category.name'), with: 'Neighbourhood planning'
    click_button I18n.t('helpers.submit.frm_category.create')

    expect(page).to have_content(I18n.t('frm.admin.category.created'))
    expect(page).to have_content('Neighbourhood planning')
  end

  it 'updates an existing category' do
    category = create(:frm_category, group: group, name: 'Initial name')
    visit group_frm_admin_categories_path(group)

    within('tbody tr', text: category.name) { click_link I18n.t('frm.admin.categories.edit') }
    fill_in I18n.t('simple_form.labels.frm_category.name'), with: 'Updated section'
    click_button I18n.t('helpers.submit.frm_category.update')

    expect(page).to have_content(I18n.t('frm.admin.category.updated'))
    expect(page).to have_content('Updated section')
  end
end
