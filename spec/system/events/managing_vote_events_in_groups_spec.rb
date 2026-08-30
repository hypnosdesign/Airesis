require 'rails_helper'
require 'requests_helper'

RSpec.describe 'voting event workflow', :js, seeds: true do
  let!(:owner) { create(:user) }
  let!(:group) { create(:group, current_user_id: owner.id) }
  let!(:member) { create(:user) }

  before do
    create_participation(member, group)
    login_as member, scope: :user
  end

  def set_datetime(selector, value)
    page.execute_script(<<~JS, selector, value.strftime('%Y-%m-%dT%H:%M'))
      const element = document.querySelector(arguments[0]);
      element.value = arguments[1];
      element.dispatchEvent(new Event('input', { bubbles: true }));
      element.dispatchEvent(new Event('change', { bubbles: true }));
    JS
  end

  it 'creates a voting window from one complete form' do
    visit new_group_event_path(group, event_type_id: EventType::VOTATION)

    title = 'Neighbourhood budget vote'
    fill_in I18n.t('activerecord.attributes.event.title'), with: title
    fill_in I18n.t('activerecord.attributes.event.description'), with: 'Choose the shared budget priorities.'
    set_datetime('#event_starttime', 2.days.from_now.change(min: 0, sec: 0))
    set_datetime('#event_endtime', 3.days.from_now.change(min: 0, sec: 0))

    expect(page).to have_no_field('event_municipality_query')
    expect(page).to have_button(I18n.t('pages.events.new.submit'), disabled: false)
    click_button I18n.t('pages.events.new.submit')

    expect(page).to have_content(I18n.t('info.events.event_created'), wait: 10)
    created = Event.order(:id).last
    expect(page).to have_current_path(group_event_path(group, created))
    expect(page).to have_content(title)
    expect(created).to be_votation
    expect(created.user).to eq(member)
  end
end
