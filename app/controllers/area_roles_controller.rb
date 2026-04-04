class AreaRolesController < ApplicationController
  layout :choose_layout

  before_action :load_group

  authorize_resource :group
  load_and_authorize_resource :group_area, through: :group
  load_and_authorize_resource through: :group_area

  def new
    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  def edit
    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  def create
    respond_to do |format|
      if @area_role.save
        flash[:notice] = t('info.participation_roles.role_created')
        format.turbo_stream
        format.html { redirect_to [@group, @group_area] }
      else
        flash[:error] = t('error.participation_roles.role_created')
        format.turbo_stream { render partial: 'layouts/flash_stream', status: :unprocessable_entity }
        format.html { render action: :new }
      end
    end
  end

  def update
    if @area_role.update(area_role_params)
      flash[:notice] = t('info.participation_roles.role_updated')
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: group_group_area_path(@group, @group_area) }
      end
    else
      flash[:error] = t('error.participation_roles.role_updated')
      respond_to do |format|
        format.turbo_stream { render partial: 'layouts/flash_stream', status: :unprocessable_entity }
        format.html { redirect_back fallback_location: group_group_area_path(@group, @group_area) }
      end
    end
  end

  def destroy
    @area_role.destroy
    flash[:notice] = t('info.participation_roles.role_deleted')
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: group_group_area_path(@group, @group_area) }
    end
  end

  def change_permissions
    gp = @group_area.area_participations.find_by(user_id: params[:user_id])
    gp.area_role_id = @area_role.id
    gp.save!
    flash[:notice] = t('info.participation_roles.role_changed')
    respond_to do |format|
      format.turbo_stream { render partial: 'layouts/flash_stream' }
      format.html { redirect_back fallback_location: group_group_area_path(@group, @group_area) }
    end
  end

  protected

  def area_role_params
    params[:area_role].
      permit(:name, :description,
             :view_proposals, :participate_proposals, :insert_proposals, :vote_proposals, :choose_date_proposals)
  end

  def load_group_area
    @group_area = GroupArea.find(params[:group_area_id])
  end

  def load_area_role
    @area_role = AreaRole.find(params[:id])
  end

  def portavoce_required
    unless (current_user && (@group.portavoce.include? current_user)) || is_admin?
      flash[:error] = t('error.portavoce_required')
      redirect_to group_url(@group)
    end
  end

  private

  def choose_layout
    'groups'
  end
end
