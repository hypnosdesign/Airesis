class AreaParticipationsController < ApplicationController
  layout 'groups'

  before_action :load_group

  before_action :authenticate_user!
  before_action :enable_content_landmark

  authorize_resource :group
  load_and_authorize_resource :group_area, through: :group

  load_and_authorize_resource through: :group_area

  def create
    participant = @group.participants.find(area_participation_params[:user_id])
    @area_participation.user = participant
    @area_participation.area_role_id = @group_area.area_role_id
    if @area_participation.save
      flash[:notice] = t('info.area_participation.create')
    else
      flash[:error] = t('error.area_participation.create')
    end
    prepare_group_areas
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: group_group_area_path(@group, @group_area) }
    end
  end

  def destroy
    @area_participation.destroy
    flash[:notice] = t('info.area_participation.destroy')
    prepare_group_areas
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: group_group_area_path(@group, @group_area) }
    end
  end

  protected

  def area_participation_params
    params.require(:area_participation).permit(:user_id)
  end

  def enable_content_landmark
    @content_landmark = true
  end

  def prepare_group_areas
    @group_areas = @group.group_areas.includes(area_participations: %i[user area_role])
    @group_participations = @group.participants.includes(:image).order(:surname, :name)
  end
end
