require 'rails_helper'
require 'requests_helper'

RSpec.describe 'meeting event workflow', :js, seeds: true do
  let!(:organizer) { create(:user) }
  let!(:group) { create(:group, current_user_id: organizer.id) }
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

  it 'creates a meeting with explicit terminal actions and no legacy JavaScript' do
    visit new_group_event_path(group, event_type_id: EventType::MEETING)

    expect(page).to have_css('main#main-content', count: 1)
    expect(page).to have_css('h1', count: 1)
    expect(page).to have_button(I18n.t('pages.events.new.submit'))
    expect(page).to have_link(I18n.t('buttons.cancel'))

    title = 'Accessible neighbourhood workshop'
    fill_in I18n.t('activerecord.attributes.event.title'), with: title
    fill_in I18n.t('activerecord.attributes.event.description'), with: 'Plan responsibilities and access needs together.'
    starttime = 2.days.from_now.change(min: 0, sec: 0)
    set_datetime('#event_starttime', starttime)
    set_datetime('#event_endtime', starttime + 2.hours)
    municipality = Municipality.first
    fill_in 'event_municipality_query', with: municipality.description
    expect(page).to have_css(
      "[data-municipality-select-target=\"id\"][value=\"#{municipality.id}\"]",
      visible: :all,
      wait: 5
    )
    fill_in I18n.t('activerecord.attributes.place.address'), with: 'Community Hall'

    expect(page).to have_button(I18n.t('pages.events.new.submit'), disabled: false)
    click_button I18n.t('pages.events.new.submit')

    expect(page).to have_content(I18n.t('info.events.event_created'), wait: 10)
    created = Event.order(:id).last
    expect(page).to have_current_path(group_event_path(group, created))
    expect(page).to have_content(title)
    expect(page).to have_content('Community Hall')
    expect(created.user).to eq(member)
    expect(created.groups).to contain_exactly(group)
  end

  it 'lets a member save and correct attendance, then add a root comment' do
    event = create(:meeting_event, user: organizer, private: true)
    create(:meeting_organization, event: event, group: group)

    visit group_event_path(group, event)

    semantic_order = page.evaluate_script(<<~JS)
      Array.from(document.querySelector('main#main-content').querySelectorAll(
        '#event-description-title, aside[aria-label], #participants_container, #event-comments-title'
      )).map((element) => element.id || element.tagName)
    JS
    expect(semantic_order).to eq(
      %w[event-description-title ASIDE participants_container event-comments-title]
    )

    within('#participation_panel_container') do
      choose I18n.t('buttons.yes_word')
      fill_in I18n.t('activerecord.attributes.meeting_participation.guests'), with: 1
      fill_in I18n.t('activerecord.attributes.meeting_participation.comment'), with: 'I can help at the welcome desk.'
      click_button I18n.t('pages.events.show.save_attendance')
    end
    expect(page).to have_content(I18n.t('info.events.attendance_saved'))
    expect(page).to have_content('I can help at the welcome desk.')

    within('#participation_panel_container') do
      choose I18n.t('buttons.no_word')
      click_button I18n.t('pages.events.show.update_attendance')
    end
    expect(page).to have_content(I18n.t('pages.events.show.attending_count', count: 0), wait: 5)
    expect(MeetingParticipation.find_by!(meeting: event.meeting, user: member).response).to eq('N')

    fill_in I18n.t('pages.proposals.show.add_comment'), with: 'Please confirm the step-free entrance.'
    click_button I18n.t('pages.event_comments.new.insert_comment')

    expect(page).to have_content('Please confirm the step-free entrance.')
    expect(event.event_comments.find_by!(user: member).comment).to be_nil
  end

  it 'uses a list-first calendar without document overflow on mobile' do
    visit group_events_path(group)
    page.current_window.resize_to(390, 844)

    expect(page.evaluate_script('window.matchMedia("(max-width: 639px)").matches')).to be(true)
    expect(page).to have_css('#fc-calendar[data-calendar-view]', wait: 10)
    expect(page.evaluate_script('document.querySelector("#fc-calendar")?.dataset.calendarView')).to eq('listWeek')
    expect(page).to have_css('#fc-calendar .fc-list', wait: 10)
    button_metrics = page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll('#fc-calendar .fc-button')).map((button) => {
        const box = button.getBoundingClientRect();
        return [box.width, box.height, getComputedStyle(button).backgroundColor];
      })
    JS
    expect(button_metrics).to all(satisfy do |width, height, background|
      width >= 44 && height >= 44 && ['transparent', 'rgba(0, 0, 0, 0)'].exclude?(background)
    end)
    dimensions = page.evaluate_script('[document.documentElement.scrollWidth, document.documentElement.clientWidth]')
    expect(dimensions.first).to be <= dimensions.last
    expect(page).to have_css('main#main-content', count: 1)
    expect(page).to have_css('h1', count: 1)
  ensure
    page.current_window.resize_to(1400, 1400)
  end
end
