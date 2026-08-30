class AreaRolesController < ApplicationController
  layout :choose_layout

  before_action :authenticate_user!
  before_action :enable_content_landmark
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
        format.turbo_stream { render 'area_roles/errors/form', status: :unprocessable_content }
        format.html { render :new, status: :unprocessable_content }
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
        format.turbo_stream { render 'area_roles/errors/form', status: :unprocessable_content }
        format.html { render :edit, status: :unprocessable_content }
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
    participation = @group_area.area_participations.find_by!(user_id: params.expect(:user_id))
    participation.update!(area_role: @area_role)
    flash[:notice] = t('info.participation_roles.role_changed')
    respond_to do |format|
      format.turbo_stream { render partial: 'layouts/flash_stream' }
      format.html { redirect_back fallback_location: group_group_area_path(@group, @group_area) }
    end
  end

  protected

  def area_role_params
    params.expect(area_role: %i[name description view_proposals participate_proposals insert_proposals
                                vote_proposals choose_date_proposals])
  end

  private

  def choose_layout
    'groups'
  end

  def enable_content_landmark
    @content_landmark = true
  end
end
