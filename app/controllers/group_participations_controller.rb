class GroupParticipationsController < ApplicationController
  layout 'groups'

  before_action :load_group

  before_action :authenticate_user!

  load_and_authorize_resource :group
  load_and_authorize_resource through: :group, except: %i[send_email destroy_all build_csv change_user_permission]

  def index
    @page_title = t('pages.group_participations.index.title')
    @search_participant = @group.search_participants.build(search_participant_params)
    @unscoped_group_participations = @search_participant.results
    @pagy, @group_participations = pagy(@unscoped_group_participations, items: GroupParticipation::PER_PAGE)

    respond_to do |format|
      format.html
      format.turbo_stream
      format.json
      format.csv { send_data build_csv }
    end
  end

  def build_csv
    authorize! :index, GroupParticipation
    CSV.generate do |csv|
      csv << [t('pages.groups.participations.surname'), t('pages.groups.participations.name'), t('pages.groups.participations.role'), t('pages.groups.participations.member_since')]
      @unscoped_group_participations.each do |group_participation|
        csv << [group_participation.user.surname, group_participation.user.name, group_participation.participation_role.name, group_participation.created_at ? (l group_participation.created_at) : ' ']
      end
    end
  end

  # changes the role of a user

  def change_user_permission
    @group_participation = @group.group_participations.find(params[:id])
    @group_participation.participation_role = ParticipationRole.find(params[:participation_role_id])
    authorize! :change_user_permission, @group_participation
    @group_participation.save!
    flash[:notice] = t('info.participation_roles.role_changed')
    respond_to do |format|
      format.turbo_stream { render partial: 'layouts/flash_stream' }
      format.html { redirect_back fallback_location: group_path(@group) }
    end
  end

  # send a massive email to all users

  def send_email
    ids = params[:message][:receiver_ids]
    subject = params[:message][:subject]
    body = params[:message][:body]
    ResqueMailer.massive_email(current_user.id, ids, @group.id, subject, body).deliver_later
    flash[:notice] = t('info.message_sent')
    respond_to do |format|
      format.turbo_stream { render partial: 'layouts/flash_stream' }
      format.html { redirect_back fallback_location: group_path(@group) }
    end
  end

  # destroy all selected participations

  def destroy_all
    ids = params[:destroy][:ids].split(',')
    GroupParticipation.transaction do
      ids.each do |id|
        group_participation = GroupParticipation.find(id)
        next unless group_participation.group == @group
        next if group_participation.user == current_user

        group_participation_request = GroupParticipationRequest.find_by(user_id: group_participation.user_id, group_id: group_participation.group_id)
        group_participation_request.destroy
        group_participation.destroy
        AreaParticipation.joins(group_area: :group).where(['groups.id = ? AND area_participations.user_id = ?', group_participation.group_id, group_participation.user_id]).readonly(false).destroy_all
      end
    end
    flash[:notice] = t('info.participations_destroyed')
  rescue StandardError
    flash[:error] = t('error.participations_destroyed')
  ensure
    respond_to do |format|
      format.turbo_stream { render partial: 'layouts/flash_stream' }
      format.html { redirect_back fallback_location: group_path(@group) }
    end
  end

  def destroy
    @group_participation.destroy
    flash[:notice] =
      current_user == @group_participation.user ?
        t('info.group_participations.destroy_ok_1') :
        t('info.participation_roles.user_removed_from_group', name: @group_participation.user.fullname)

    redirect_back(fallback_location: group_path(@group))
  end

  protected

  def search_participant_params
    params[:search_participant] ? params.require(:search_participant).permit(:keywords, :role_id, :status_id) : {}
  end
end
