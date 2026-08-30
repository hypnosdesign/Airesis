require 'rails_helper'
require 'requests_helper'
require 'cancan/matchers'

RSpec.describe 'decide the voting date for a proposal', :js, seeds: true do
  let!(:user) { create(:user) }
  let!(:group) { create(:group, current_user_id: user.id) }
  let!(:proposal) do
    create(
      :group_proposal,
      quorum: group.quorums.active.first,
      current_user_id: user.id,
      group_proposals: [GroupProposal.new(group: group)]
    )
  end

  before do
    login_as user, scope: :user
  end

  def set_datetime(selector, value)
    page.execute_script(<<~JS, selector, value.strftime('%Y-%m-%dT%H:%M'))
      const element = document.querySelector(arguments[0]);
      element.value = arguments[1];
      element.dispatchEvent(new Event('input', { bubbles: true }));
      element.dispatchEvent(new Event('change', { bubbles: true }));
    JS
  end

  it 'creates a voting window and returns to the proposal' do
    2.times do
      ranker = create(:user)
      create(:positive_ranking, proposal: proposal, user: ranker)
    end
    proposal.check_phase(true)
    proposal.reload
    expect(proposal).to be_waiting_date

    visit group_proposal_path(group, proposal)
    click_link I18n.t('pages.proposals.show.choose_new_votation_period_button')

    expect(page).to have_current_path(new_group_event_path(group), ignore_query: true)
    fill_in I18n.t('activerecord.attributes.event.title'), with: 'Proposal voting window'
    fill_in I18n.t('activerecord.attributes.event.description'), with: 'A clear period for the final decision.'
    set_datetime('#event_starttime', 2.days.from_now.change(min: 0, sec: 0))
    set_datetime('#event_endtime', 3.days.from_now.change(min: 0, sec: 0))
    expect(page).to have_button(I18n.t('pages.events.new.submit'), disabled: false)
    click_button I18n.t('pages.events.new.submit')

    expect(page).to have_content(I18n.t('info.events.event_created'), wait: 10)
    expect(page).to have_current_path(group_proposal_path(group, proposal))
    proposal.reload
    expect(proposal.vote_period).to be_votation
    expect(proposal).to be_waiting
    expect(page).to have_content(
      I18n.t(
        'pages.proposals.show.votation_message',
        from: I18n.l(proposal.vote_period.starttime),
        to: I18n.l(proposal.vote_period.endtime)
      )
    )
  end
end
