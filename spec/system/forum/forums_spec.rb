require 'rails_helper'
require 'requests_helper'

RSpec.describe 'forum discovery', :js do
  let(:owner) { create(:user) }
  let(:group) { create(:group, current_user_id: owner.id) }
  let(:category) { create(:frm_category, group: group, visible_outside: true, name: 'Public discussions') }
  let(:forum) { create(:frm_forum, group: group, category: category, visible_outside: true, name: 'Civic forum') }
  let!(:topic) { create(:approved_topic, forum: forum, user: owner, subject: 'A visible civic question') }

  before do
    load_database
    topic
  end

  it 'lets a visitor move from the forum directory to a public topic' do
    visit group_forums_path(group)

    expect(page).to have_selector('h1', text: I18n.t('frm.forums.index.title'))
    expect(page).to have_link(forum.name)

    click_link forum.name
    expect(page).to have_selector('h1', text: forum.name)
    expect(page).to have_link(topic.subject)

    click_link topic.subject
    expect(page).to have_selector('h1', text: topic.subject)
    expect(page).to have_content(topic.posts.first.text.to_plain_text)
  end

  it 'does not overflow horizontally at a phone viewport' do
    page.current_window.resize_to(390, 844)

    visit group_forum_path(group, forum)

    overflow = page.evaluate_script('document.documentElement.scrollWidth > document.documentElement.clientWidth')
    expect(overflow).to be(false)
  ensure
    page.current_window.resize_to(1400, 1400)
  end
end
