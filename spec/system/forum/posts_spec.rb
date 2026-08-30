require 'rails_helper'
require 'requests_helper'

RSpec.describe 'forum replies', :js do
  let(:owner) { create(:user) }
  let(:group) { create(:group, current_user_id: owner.id) }
  let(:category) { create(:frm_category, group: group, visible_outside: true) }
  let(:forum) { create(:frm_forum, group: group, category: category, visible_outside: true) }
  let(:topic) { create(:approved_topic, forum: forum, user: owner) }

  before do
    load_database
    topic
    login_as owner, scope: :user
  end

  it 'posts a reply with Trix and shows the relationship to the original post' do
    visit group_forum_topic_path(group, forum, topic)
    within('#post_1') { click_link I18n.t('frm.topic.reply') }

    body = 'I support this direction and suggest publishing the timetable.'
    find('trix-editor').set(body)
    click_button I18n.t('frm.post.buttons.reply')

    expect(page).to have_content(I18n.t('frm.post.created'))
    expect(page).to have_content(body)
    expect(page).to have_content(I18n.t('frm.posts.post.in_reply_to'))
  end

  it 'edits an owned reply with Trix' do
    visit group_forum_topic_path(group, forum, topic)
    within('#post_1') { click_link I18n.t('frm.post.buttons.edit') }

    body = 'Updated opening contribution with clearer evidence.'
    find('trix-editor').set(body)
    click_button I18n.t('frm.post.buttons.edit')

    expect(page).to have_content(I18n.t('edited', scope: 'frm.post'))
    expect(page).to have_content(body)
  end

  it 'deletes an owned reply without deleting a topic that still has content' do
    create(:post, topic: topic, user: owner)
    visit group_forum_topic_path(group, forum, topic)

    within('#post_2') do
      accept_confirm { click_link I18n.t('delete', scope: 'frm.topic') }
    end

    expect(page).to have_content(I18n.t('frm.post.deleted'))
    expect(page).to have_selector('#post_1')
  end

  it 'keeps post content and actions inside a phone viewport' do
    page.current_window.resize_to(390, 844)
    visit group_forum_topic_path(group, forum, topic)

    expect(page).to have_selector('#post_1')
    overflow = page.evaluate_script('document.documentElement.scrollWidth > document.documentElement.clientWidth')
    expect(overflow).to be(false)
  ensure
    page.current_window.resize_to(1400, 1400)
  end
end
