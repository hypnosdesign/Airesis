class EventsController < ApplicationController
  layout :choose_layout

  before_action :load_group, only: %i[index new create]
  before_action :enable_content_landmark

  load_and_authorize_resource :group
  load_and_authorize_resource :event, through: :group, shallow: true

  def index
    authorize! :view_data, @group if @group
    respond_to do |format|
      format.html do
        @page_title = @group ? "#{t('pages.events.index.title')} - #{@group.name}" : t('pages.events.index.title')
      end
      format.ics { respond_with_ical_index }
      format.json { respond_with_json_index }
    end
  end

  def show
    authorize! :view_data, @group if @group
    @page_title = @event.title
    prepare_show_comments

    respond_to do |format|
      format.html { prepare_votation }
      format.turbo_stream
      format.ics do
        calendar = Icalendar::Calendar.new
        calendar.add_event(@event.to_ics)
        calendar.publish
        render plain: calendar.to_ical
      end
    end
  end

  def new
    event_type = params[:event_type_id].presence || EventType::MEETING
    return unless authorize_event_creation!(event_type)

    @page_title = event_form_title(event_type)
    @starttime = calculate_starttime
    @endtime = calculate_endtime(@starttime)
    @event = Event.new(
      starttime: @starttime,
      endtime: @endtime,
      period: 'Non ripetere',
      event_type_id: event_type,
      proposal_id: params[:proposal_id],
      private: @group.present?
    )
    prepare_meeting_form
  end

  def create
    return unless authorize_event_creation!(event_params[:event_type_id])

    @event.assign_attributes(event_params)
    @event.user = current_user

    Event.transaction do
      @event.save!
      MeetingOrganization.find_or_create_by!(event: @event, group: @group) if @group
      attach_proposal!
    end

    flash[:notice] = t('info.events.event_created')
    redirect_after_event_change(event_destination)
  rescue ActiveRecord::RecordInvalid
    prepare_meeting_form
    @page_title = event_form_title(@event.event_type_id)
    flash.now[:error] = t('error.events.creation')
    render_event_form_error(:new)
  end

  def move
    authorize! :update, @event
    @event.move(params[:minute_delta].to_i, params[:day_delta].to_i, params[:all_day])
    head :ok
  end

  def resize
    authorize! :update, @event
    @event.resize(params[:minute_delta].to_i, params[:day_delta].to_i)
    head :ok
  end

  def edit
    @page_title = t('pages.events.edit.title', title: @event.title)
    prepare_meeting_form
  end

  def update
    if @event.update(event_params)
      flash[:notice] = t('info.events.event_updated')
      redirect_after_event_change(event_destination)
    else
      @page_title = t('pages.events.edit.title', title: @event.title)
      prepare_meeting_form
      flash.now[:error] = t('error.events.update')
      render_event_form_error(:edit)
    end
  end

  def destroy
    @event.destroy!
    flash[:notice] = t('info.events.event_deleted')
    group = @group || @event.groups.first
    destination = group ? group_events_path(group) : events_path
    redirect_after_event_change(destination)
  end

  protected

  def calculate_starttime
    return 10.minutes.from_now unless params[:starttime]

    value = Time.zone.at(params[:starttime].to_i / 1000)
    value = value.change(hour: Time.zone.now.hour, min: Time.zone.now.min) unless params[:has_time] == 'true'
    value
  end

  def event_params
    permitted = params.require(:event).permit(
      :id,
      :title,
      :starttime,
      :endtime,
      :frequency,
      :all_day,
      :description,
      :event_type_id,
      :private,
      :proposal_id,
      meeting_attributes: [
        :id,
        place_attributes: %i[id municipality_id address latitude_original longitude_original latitude_center
                             longitude_center zoom]
      ]
    )
    permitted.delete(:meeting_attributes) if permitted[:event_type_id].to_s == EventType::VOTATION.to_s
    permitted
  end

  def choose_layout
    @group ? 'groups' : 'open_space'
  end

  private

  def enable_content_landmark
    @content_landmark = true
  end

  def calculate_endtime(starttime)
    return Time.zone.at(params[:endtime].to_i / 1000) if params[:endtime].present?

    starttime + 1.hour
  end

  def authorize_event_creation!(event_type)
    if @group
      authorize! event_type.to_s == EventType::VOTATION.to_s ? :create_date : :create_event, @group
      authorize_requested_proposal!
    elsif requested_proposal_id
      authorize_requested_proposal!
    else
      return false unless admin_required
    end
    true
  end

  def event_form_title(event_type)
    suffix = event_type.to_s == EventType::VOTATION.to_s ? t('pages.events.new.title_event') : t('pages.events.new.title_meeting')
    @group ? "#{suffix} — #{@group.name}" : suffix
  end

  def prepare_meeting_form
    return unless @event.meeting?

    @meeting = @event.meeting || @event.build_meeting
    @place = @meeting.place || @meeting.build_place
  end

  def prepare_show_comments
    @event_comment = @event.event_comments.new
    @pagy, @event_comments = pagy(
      :offset,
      @event.event_comments.includes(:user, :likes).order(created_at: :desc),
      limit: COMMENTS_PER_PAGE
    )
  end

  def prepare_votation
    return unless @event.votation?

    @proposals = @event.proposals.for_list(current_user.try(:id))
    @proposals_count = @event.proposals.count
  end

  def attach_proposal!
    return if @event.proposal_id.blank?

    @proposal.set_votation_date(@event.id)
  end

  def requested_proposal_id
    params.dig(:event, :proposal_id).presence || params[:proposal_id].presence
  end

  def authorize_requested_proposal!
    return unless requested_proposal_id

    proposals = @group ? @group.proposals : Proposal.all
    @proposal = proposals.find(requested_proposal_id)
    authorize! :set_votation_date, @proposal
  end

  def event_destination
    if @proposal
      @group ? group_proposal_path(@group, @proposal) : proposal_path(@proposal)
    elsif @group
      group_event_path(@group, @event)
    else
      event_path(@event)
    end
  end

  def redirect_after_event_change(destination)
    respond_to do |format|
      format.html { redirect_to destination, status: :see_other }
      format.turbo_stream { redirect_to destination, status: :see_other }
    end
  end

  def render_event_form_error(template)
    respond_to do |format|
      format.html { render template, status: :unprocessable_content }
      format.turbo_stream { render 'events/errors/form', status: :unprocessable_content }
    end
  end

  def respond_with_ical_index
    calendar = Icalendar::Calendar.new
    @events.each { |event| calendar.add_event(event.to_ics) }
    calendar.publish
    render plain: calendar.to_ical
  end

  def respond_with_json_index
    starts_at = Time.zone.parse(params['start'])
    ends_at = Time.zone.parse(params['end'])
    @events = @events.time_scoped(starts_at, ends_at)
    @events = @events.in_territory(current_domain.territory) unless @group
    @events = @events.includes(:groups) unless @group
    render json: @events.map { |event| generate_event_obj(event) }
  end

  def generate_event_obj(event)
    event_obj = event.to_fc
    group = @group || event.groups.first
    if group
      event_obj[:group] = group.name
      event_obj[:group_url] = group_url(group)
    end
    event_obj[:url] = @group ? group_event_url(@group, event) : event_url(event)
    event_obj[:editable] &&= can?(:update, event)
    event_obj
  end

  def render_404(exception = nil)
    log_error(exception) if exception
    respond_to do |format|
      @title = t('error.error_404.events.title')
      @message = t('error.error_404.events.description')
      format.html { render 'errors/404', status: :not_found, layout: true }
    end
    true
  end
end
