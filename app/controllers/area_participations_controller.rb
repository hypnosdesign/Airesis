class AreaParticipationsController < ApplicationController
  layout 'groups'

  before_action :load_group

  before_action :authenticate_user!

  authorize_resource :group
  load_and_authorize_resource :group_area, through: :group

  before_action :load_area_participation, only: :destroy

  load_and_authorize_resource through: :group_area

  def create
    # part = @group_area.area_participations.new
    # part.user_id = params[:user_id]

    @area_participation.area_role_id = @group_area.area_role_id
    if @area_participation.save
      flash[:notice] = t('info.area_participation.create')
    else
      flash[:error] = t('error.area_participation.create')
    end
    respond_to do |format|
      format.turbo_stream { render partial: 'layouts/flash_stream' }
      format.html { redirect_back fallback_location: group_group_area_path(@group, @group_area) }
    end
  end

  def destroy
    @area_participation.destroy
    flash[:notice] = t('info.area_participation.destroy')
    respond_to do |format|
      format.turbo_stream { render partial: 'layouts/flash_stream' }
      format.html { redirect_back fallback_location: group_group_area_path(@group, @group_area) }
    end
  end

  protected

  def load_area_participation
    @area_participation = @group_area.area_participations.find_by(user_id: area_participation_params[:user_id])
  end

  def area_participation_params
    params.require(:area_participation).permit(:user_id)
  end
end
