require 'rails_helper'
require 'requests_helper'

RSpec.describe 'forum management', :js do
  let(:owner) { create(:user) }
  let(:group) { create(:group, current_user_id: owner.id) }
  let(:category) { create(:frm_category, group: group, visible_outside: true) }
  let(:forum) { create(:frm_forum, group: group, category: category, visible_outside: true) }

  before do
    load_database
    forum
    login_as owner, scope: :user
  end

  it 'exposes the three scoped administration areas' do
    visit group_frm_admin_root_path(group)

    expect(page).to have_selector('h1', text: I18n.t('frm.admin.area'))
    expect(page).to have_link(I18n.t('frm.admin.category.index'))
    expect(page).to have_link(I18n.t('frm.admin.forum.index'))
    expect(page).to have_link(I18n.t('frm.admin.mod.index'))
  end

  it 'creates a moderator team' do
    visit group_frm_admin_mods_path(group)
    click_link I18n.t('frm.admin.mod.new')

    fill_in I18n.t('simple_form.labels.frm_mod.name'), with: 'Civic moderation team'
    click_button I18n.t('helpers.submit.frm_mod.create')

    expect(page).to have_content(I18n.t('frm.admin.group.created'))
    expect(page).to have_selector('h1', text: 'Civic moderation team')
  end

  it 'moderates a pending reply inside the current forum' do
    topic = create(:approved_topic, forum: forum, user: owner)
    post_record = create(:post, topic: topic, user: owner)
    post_record.update!(state: 'pending_review')

    visit group_frm_forum_moderator_tools_path(group, forum)

    expect(page).to have_selector('h1', text: I18n.t('frm.moderation.index.title', forum: forum))
    within('#post_1') { choose I18n.t('frm.posts.moderation.approve') }
    click_button I18n.t('frm.posts.moderation.moderate')

    expect(page).to have_content(I18n.t('frm.posts.moderation.success'))
    expect(post_record.reload.state).to eq('approved')
  end
end
