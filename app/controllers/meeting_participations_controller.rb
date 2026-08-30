class MeetingParticipationsController < ApplicationController
  before_action :authenticate_user!
  before_action :enable_content_landmark

  load_and_authorize_resource :event
  load_and_authorize_resource through: :event

  def create
    @meeting_participation.user = current_user
    persist_participation
  end

  def update
    @meeting_participation = @event.meeting_participations.where(user_id: current_user.id).find(params[:id])
    authorize! :update, @meeting_participation
    @meeting_participation.assign_attributes(meeting_participation_params)
    persist_participation
  end

  protected

  def meeting_participation_params
    params.require(:meeting_participation).permit(:comment, :guests, :response)
  end

  private

  def enable_content_landmark
    @content_landmark = true
  end

  def event_destination
    group = @event.groups.first
    group ? group_event_path(group, @event) : event_path(@event)
  end

  def persist_participation
    @meeting_participation.guests = 0 if @meeting_participation.response == 'N'
    if @meeting_participation.save
      flash[:notice] = t('info.events.attendance_saved')
      respond_to do |format|
        format.html { redirect_to event_destination, status: :see_other }
        format.turbo_stream { render :create }
      end
    else
      flash.now[:error] = t('error.event_answer')
      respond_to do |format|
        format.html { render_event_show }
        format.turbo_stream { render 'meeting_participations/errors/form', status: :unprocessable_content }
      end
    end
  end

  def render_event_show
    @page_title = @event.title
    @group = @event.groups.first
    @event_comment = @event.event_comments.new
    @pagy, @event_comments = pagy(
      :offset,
      @event.event_comments.includes(:user, :likes).order(created_at: :desc),
      limit: COMMENTS_PER_PAGE
    )
    render 'events/show', status: :unprocessable_content, layout: @group ? 'groups' : 'open_space'
  end
end
