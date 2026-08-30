class GroupAreasController < ApplicationController
  layout :choose_layout

  before_action :authenticate_user!
  before_action :enable_content_landmark

  before_action :load_group
  authorize_resource :group

  before_action :configuration_required

  load_and_authorize_resource through: :group

  def index
    @page_title = t('pages.groups.edit_work_areas.manage_group_areas')
    if @group.enable_areas
      @group_areas = @group.group_areas.includes(area_participations: %i[user area_role])
      @group_participations = @group.participants.includes(:image).order(:surname, :name)
    else
      render 'area_inactive'
    end
  end

  def show
    @page_title = @group_area.name
    @group_participations = @group_area.participants
  end

  def new
    @group_area = @group.group_areas.build
    @group_area.default_role_actions = DEFAULT_AREA_ACTIONS
    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  def edit
    authorize! :update, @group_area
    @page_title = t('pages.groups.edit_work_areas.manage.title')
    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  def edit_permissions
    @page_title = t('pages.groups.edit_permissions.title')
  end

  def create
    @group_area.current_user_id = current_user.id
    if @group_area.save
      @group_areas = @group.group_areas.includes(:participants)
      @group_participations = @group.participants
      respond_to do |format|
        flash[:notice] = t('info.groups.work_area.area_created')
        format.turbo_stream
        format.html { redirect_to [@group, @group_area] }
      end
    else
      respond_to do |format|
        flash[:error] = t('error.groups.work_area.area_created')
        format.turbo_stream { render 'group_areas/errors/create', status: :unprocessable_content }
        format.html { render :new, status: :unprocessable_content }
      end
    end
  end

  def update
    if @group_area.update(group_area_params)
      respond_to do |format|
        flash[:notice] = t('info.groups.area_updated')
        format.html { redirect_to([@group, @group_area]) }
      end
    else
      flash[:error] = t('error.area.update')
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_content }
      end
    end
  end

  def destroy
    authorize! :destroy, @group_area
    @group_area.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: group_group_areas_path(@group) }
    end
  end

  def participants_list_panel
    @group_participations = @group_area.area_participations.includes(:user)
  end

  protected

  def group_area_params
    params.require(:group_area).permit(:name, :description, :default_role_name, :default_role_actions)
  end

  def configuration_required
    unless ::Configuration.group_areas
      flash[:error] = t('error.configuration_required')
      redirect_to edit_group_path(@group)
    end
  end

  private

  def choose_layout
    'groups'
  end

  def enable_content_landmark
    @content_landmark = true
  end
end
