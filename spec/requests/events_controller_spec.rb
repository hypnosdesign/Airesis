require 'rails_helper'
require 'requests_helper'

RSpec.describe EventsController, seeds: true do
  let!(:user) { create(:user) }
  let!(:admin) { create(:admin) }
  let!(:event) { create(:meeting_event, user: admin) }
  let!(:group) { create(:group, current_user_id: admin.id) }

  def event_attributes(overrides = {})
    {
      title: 'Accessible planning session',
      description: 'Plan the next civic workshop together.',
      starttime: 2.days.from_now.change(sec: 0),
      endtime: 2.days.from_now.change(sec: 0) + 2.hours,
      event_type_id: EventType::MEETING,
      private: true,
      meeting_attributes: {
        place_attributes: {
          municipality_id: Municipality.first.id,
          address: 'Community Hall'
        }
      }
    }.deep_merge(overrides)
  end

  describe 'route inventory' do
    it 'publishes only implemented G07 actions' do
      controllers = %w[events event_comments meeting_participations]
      routes = Rails.application.routes.routes.select do |route|
        controllers.include?(route.defaults[:controller])
      end

      expect(routes.size).to eq(26)
      expect(routes.count { |route| route.verb.include?('GET') }).to eq(8)
      expect(routes).to all(satisfy do |route|
        "#{route.defaults[:controller].camelize}Controller".constantize.action_methods.include?(route.defaults[:action])
      end)
    end
  end

  describe 'GET index' do
    it 'renders the public calendar for a guest' do
      get events_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="fc-calendar"')
      expect(response.body).to include('<main')
    end

    it 'renders a public group calendar' do
      get group_events_path(group)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(group.name)
    end

    it 'returns scoped calendar JSON' do
      get events_path,
          params: { start: 1.week.ago.iso8601, end: 1.week.from_now.iso8601 },
          headers: { 'ACCEPT' => 'application/json' }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to be_an(Array)
    end

    it 'marks only events the current user can update as editable' do
      calendar_group = create(:group, current_user_id: admin.id)
      create_participation(user, calendar_group)
      owned_event = create(:meeting_event, user: user, private: false)
      locked_event = create(:meeting_event, user: admin, private: false)
      voting_event = create(:vote_event, user: user, private: false)
      [owned_event, locked_event, voting_event].each do |calendar_event|
        create(:meeting_organization, event: calendar_event, group: calendar_group)
      end
      sign_in user

      get group_events_path(calendar_group),
          params: { start: 1.week.ago.iso8601, end: 1.week.from_now.iso8601 },
          headers: { 'ACCEPT' => 'application/json' }

      events_by_id = response.parsed_body.index_by { |item| item.fetch('id').to_i }
      expect(events_by_id.fetch(owned_event.id).fetch('editable')).to be(true)
      expect(events_by_id.fetch(locked_event.id).fetch('editable')).to be(false)
      expect(events_by_id.fetch(voting_event.id).fetch('editable')).to be(false)
    end

    it 'offers an authorized admin a real top-level creation link' do
      sign_in admin

      get events_path

      create_link = response.parsed_body.at_css("a[href='#{new_event_path}']")
      expect(create_link&.text).to include(I18n.t('pages.calendar.create_event_button'))
    end
  end

  describe 'GET show' do
    it 'renders the event operations for an authorized admin' do
      sign_in admin

      get event_path(event)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="participation_panel_container"')
      expect(response.body).to include('id="eventCommentsContainer"')
      expect(response.body).to include('<main')
    end

    it 'redirects a guest away from a private event' do
      get event_path(event)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'renders a voting event with its proposal list projection' do
      vote_event = create(:vote_event, user: admin)
      create(:meeting_organization, event: vote_event, group: group)
      sign_in admin

      get group_event_path(group, vote_event)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.at_css('h1')&.text).to eq(vote_event.title)
      expect(response.body).to include(I18n.t('pages.events.show.no_voting_proposals'))
    end
  end

  describe 'GET new and edit' do
    it 'requires authentication for a top-level event' do
      get new_event_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'renders a complete group meeting form for the group admin' do
      sign_in admin

      get new_group_event_path(group, event_type_id: EventType::MEETING)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="event_form"')
      expect(response.body).to include(I18n.t('pages.events.new.submit'))
      expect(response.body).to include(I18n.t('buttons.cancel'))
    end

    it 'renders edit with a contextual title and heading' do
      sign_in admin

      get edit_event_path(event)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t('pages.events.edit.heading'))
      expect(response.parsed_body.at_css('title')&.text).to include("Edit #{event.title}")
    end
  end

  describe 'POST create' do
    it 'creates the event, meeting, place and group scope atomically' do
      sign_in admin

      expect {
        post group_events_path(group), params: { event: event_attributes }
      }.to change(Event, :count).by(1).and change(MeetingOrganization, :count).by(1)

      created = Event.order(:id).last
      expect(response).to redirect_to(group_event_path(group, created))
      expect(response).to have_http_status(:see_other)
      expect(created.user).to eq(admin)
      expect(created.groups).to contain_exactly(group)
      expect(created.place.address).to eq('Community Hall')
    end

    it 'preserves an invalid form and returns 422' do
      sign_in admin

      expect {
        post group_events_path(group), params: { event: event_attributes(title: '') }
      }.not_to change(Event, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('id="event_form"')
      expect(response.body).to include(I18n.t('error.events.creation'))
    end

    it 'does not attach a proposal from another group' do
      other_group = create(:group)
      foreign_proposal = create(
        :group_proposal,
        current_user_id: admin.id,
        group_proposals: [GroupProposal.new(group: other_group)]
      )
      sign_in admin

      expect do
        post group_events_path(group),
             params: {
               event: event_attributes(
                 event_type_id: EventType::VOTATION,
                 proposal_id: foreign_proposal.id
               )
             }
      end.not_to change(Event, :count)

      expect(response).to have_http_status(:not_found)
      expect(foreign_proposal.reload.vote_period).to be_nil
    end

    it 'requires proposal-specific permission before creating its voting window' do
      group_owner = create(:user)
      proposal_owner = create(:user)
      managed_group = create(:group, current_user_id: group_owner.id)
      proposal = create(
        :group_proposal,
        current_user_id: proposal_owner.id,
        group_proposals: [GroupProposal.new(group: managed_group)]
      )
      sign_in group_owner

      expect do
        post group_events_path(managed_group),
             params: {
               event: event_attributes(
                 event_type_id: EventType::VOTATION,
                 proposal_id: proposal.id
               )
             }
      end.not_to change(Event, :count)

      expect(response).to have_http_status(:forbidden)
      expect(proposal.reload.vote_period).to be_nil
    end

    it 'rejects a meeting event as a proposal voting window atomically' do
      proposal = create(
        :group_proposal,
        current_user_id: admin.id,
        group_proposals: [GroupProposal.new(group: group)]
      )
      proposal.update!(proposal_state_id: ProposalState::WAIT_DATE)
      sign_in admin

      expect do
        post group_events_path(group),
             params: { event: event_attributes(proposal_id: proposal.id) }
      end.not_to change(Event, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(proposal.reload.vote_period).to be_nil
      expect(proposal).to be_waiting_date
    end

    it 'creates a valid proposal voting window and advances it to waiting' do
      proposal = create(
        :group_proposal,
        current_user_id: admin.id,
        group_proposals: [GroupProposal.new(group: group)]
      )
      proposal.update!(proposal_state_id: ProposalState::WAIT_DATE)
      sign_in admin

      expect do
        post group_events_path(group),
             params: {
               event: event_attributes(
                 event_type_id: EventType::VOTATION,
                 proposal_id: proposal.id
               )
             }
      end.to change(Event, :count).by(1)

      created = Event.order(:id).last
      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(group_proposal_path(group, proposal))
      expect(proposal.reload.vote_period).to eq(created)
      expect(proposal).to be_waiting
      expect(created).to be_votation
    end

    it 'does not relink a proposal that is no longer waiting for a date' do
      proposal = create(
        :group_proposal,
        current_user_id: admin.id,
        group_proposals: [GroupProposal.new(group: group)]
      )
      proposal.update!(
        proposal_state_id: ProposalState::WAIT,
        updated_at: (OTHERS_CHOOSE_VOTE_DATE_DAYS + 1).days.ago
      )
      sign_in admin

      expect do
        post group_events_path(group),
             params: {
               event: event_attributes(
                 event_type_id: EventType::VOTATION,
                 proposal_id: proposal.id
               )
             }
      end.not_to change(Event, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(proposal.reload.vote_period).to be_nil
      expect(proposal).to be_waiting
    end

    it 'rejects a voting window that has already started' do
      proposal = create(
        :group_proposal,
        current_user_id: admin.id,
        group_proposals: [GroupProposal.new(group: group)]
      )
      proposal.update!(proposal_state_id: ProposalState::WAIT_DATE)
      sign_in admin

      expect do
        post group_events_path(group),
             params: {
               event: event_attributes(
                 starttime: 2.hours.ago,
                 endtime: 1.hour.ago,
                 event_type_id: EventType::VOTATION,
                 proposal_id: proposal.id
               )
             }
      end.not_to change(Event, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(proposal.reload.vote_period).to be_nil
      expect(proposal).to be_waiting_date
    end
  end

  describe 'PATCH update' do
    it 'updates an authorized event and redirects with 303' do
      sign_in admin

      patch event_path(event), params: { event: event_attributes(title: 'Updated civic session') }

      expect(response).to have_http_status(:see_other)
      expect(event.reload.title).to eq('Updated civic session')
      expect(response).to redirect_to(event_path(event))
    end

    it 'returns 422 and preserves invalid values' do
      sign_in admin

      patch event_path(event), params: { event: event_attributes(title: '') }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('id="event_form"')
      expect(event.reload.title).not_to eq('')
    end
  end

  describe 'calendar mutations' do
    it 'moves an event for an authorized admin' do
      sign_in admin
      original = event.starttime

      post move_event_path(event), params: { minute_delta: 30, day_delta: 0, all_day: false }

      expect(response).to have_http_status(:ok)
      expect(event.reload.starttime).to eq(original + 30.minutes)
    end

    it 'does not move an event for a guest' do
      original = event.starttime

      post move_event_path(event), params: { minute_delta: 30, day_delta: 0, all_day: false }

      expect(response).to redirect_to(new_user_session_path)
      expect(event.reload.starttime).to eq(original)
    end
  end

  describe 'DELETE destroy' do
    it 'destroys an authorized event and redirects safely' do
      sign_in admin

      expect { delete event_path(event) }.to change(Event, :count).by(-1)

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(events_path)
    end
  end
end
