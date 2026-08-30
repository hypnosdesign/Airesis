require 'rails_helper'
require 'requests_helper'

RSpec.describe 'forum topics', :js do
  let(:owner) { create(:user) }
  let(:group) { create(:group, current_user_id: owner.id) }
  let(:category) { create(:frm_category, group: group, visible_outside: true) }
  let(:forum) { create(:frm_forum, group: group, category: category, visible_outside: true) }

  before do
    load_database
    login_as owner, scope: :user
  end

  it 'creates a topic with the current Trix editor' do
    visit new_group_forum_topic_path(group, forum)
    subject = 'How should we improve the public square?'
    body = 'Share concrete needs, constraints, and a proposal for the next meeting.'

    fill_in I18n.t('simple_form.labels.topic.subject'), with: subject
    find('trix-editor').set(body)
    click_button I18n.t('helpers.submit.topic.create')

    expect(page).to have_content(I18n.t('frm.topic.created'))
    expect(page).to have_selector('h1', text: subject)
    expect(page).to have_content(body)
  end

  it 'subscribes and unsubscribes with explicit state-changing verbs' do
    topic = create(:approved_topic, forum: forum, user: create(:user))
    visit group_forum_topic_path(group, forum, topic)

    click_link I18n.t('frm.topics.show.subscribe')
    expect(page).to have_content(I18n.t('frm.topic.subscribed'))
    expect(page).to have_link(I18n.t('frm.topics.show.unsubscribe'))

    click_link I18n.t('frm.topics.show.unsubscribe')
    expect(page).to have_content(I18n.t('frm.topic.unsubscribed'))
    expect(page).to have_link(I18n.t('frm.topics.show.subscribe'))
  end

  it 'lets a group administrator pin and unpin a topic' do
    topic = create(:approved_topic, forum: forum, user: owner)
    visit group_forum_topic_path(group, forum, topic)

    find('summary', text: I18n.t('frm.forum.admin_tools')).click
    click_link I18n.t('frm.topics.show.pin.false')
    expect(page).to have_content(I18n.t('frm.topic.pinned.true'))

    find('summary', text: I18n.t('frm.forum.admin_tools')).click
    click_link I18n.t('frm.topics.show.pin.true')
    expect(page).to have_content(I18n.t('frm.topic.pinned.false'))
  end

  it 'shows a clear exit from topic creation' do
    visit new_group_forum_topic_path(group, forum)

    click_link I18n.t('buttons.cancel')

    expect(page).to have_current_path(group_forum_path(group, forum))
  end
end
