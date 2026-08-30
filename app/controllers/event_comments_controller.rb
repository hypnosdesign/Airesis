class EventCommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :enable_content_landmark

  load_and_authorize_resource :event
  load_and_authorize_resource through: :event

  def create
    @event_comment.user = current_user
    @event_comment.request = request

    if @event_comment.save
      prepare_comments
      flash[:notice] = t('info.event.comment_added')
      respond_to do |format|
        format.html { redirect_to event_destination, status: :see_other }
        format.turbo_stream
      end
    else
      flash.now[:error] = t('error.event.comment_added')
      respond_to do |format|
        format.html { render_event_show }
        format.turbo_stream { render 'event_comments/errors/create', status: :unprocessable_content }
      end
    end
  end

  def destroy
    @event_comment.destroy!
    flash[:notice] = t('info.event.comment_deleted')
    respond_to do |format|
      format.html { redirect_to event_destination, status: :see_other }
      format.turbo_stream
    end
  end

  def like
    if @event_comment.likers.exists?(current_user.id)
      @event_comment.likers.delete(current_user)
    else
      @event_comment.likers << current_user
    end

    respond_to do |format|
      format.html { redirect_back fallback_location: event_destination, status: :see_other }
      format.turbo_stream
    end
  end

  protected

  def event_comment_params
    params.require(:event_comment).permit(:body)
  end

  private

  def enable_content_landmark
    @content_landmark = true
  end

  def event_destination
    group = @event.groups.first
    group ? group_event_path(group, @event) : event_path(@event)
  end

  def prepare_comments
    @pagy, @event_comments = pagy(
      :offset,
      @event.event_comments.includes(:user, :likes).order(created_at: :desc),
      limit: COMMENTS_PER_PAGE
    )
  end

  def render_event_show
    @page_title = @event.title
    @group = @event.groups.first
    prepare_comments
    render 'events/show', status: :unprocessable_content, layout: @group ? 'groups' : 'open_space'
  end
end
