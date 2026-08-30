class GroupParticipationsController < ApplicationController
  layout 'groups'

  before_action :enable_content_landmark
  before_action :load_group

  before_action :authenticate_user!

  load_and_authorize_resource :group
  load_and_authorize_resource through: :group, except: %i[send_email destroy_all build_csv change_user_permission]

  def index
    @page_title = t('pages.group_participations.index.title')
    @search_participant = @group.search_participants.build(search_participant_params)
    @unscoped_group_participations = @search_participant.results
    @pagy, @group_participations = pagy(:offset, @unscoped_group_participations, limit: GroupParticipation::PER_PAGE)

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
    authorize! :change_user_permission, @group_participation
    requested_role_id = params[:participation_role_id].to_i
    requested_role = if requested_role_id == ParticipationRole.admin.id
                       ParticipationRole.admin
                     else
                       @group.participation_roles.find(requested_role_id)
                     end
    @group_participation.participation_role = requested_role
    @group_participation.save!
    flash[:notice] = t('info.participation_roles.role_changed')
    respond_to do |format|
      format.turbo_stream { render partial: 'layouts/flash_stream' }
      format.html { redirect_back fallback_location: group_path(@group) }
    end
  end

  # send a massive email to all users

  def send_email
    authorize! :update, @group
    ids = @group.group_participations.where(user_id: receiver_ids).pluck(:user_id)
    subject = params.dig(:message, :subject).to_s
    body = params.dig(:message, :body).to_s
    ResqueMailer.massive_email(current_user.id, ids, @group.id, subject, body).deliver_later
    flash[:notice] = t('info.message_sent')
    respond_to do |format|
      format.turbo_stream { render partial: 'layouts/flash_stream' }
      format.html { redirect_back fallback_location: group_path(@group) }
    end
  end

  # destroy all selected participations

  def destroy_all
    authorize! :update, @group
    begin
      ids = params.dig(:destroy, :ids).to_s.split(',')
      GroupParticipation.transaction do
        @group.group_participations.where(id: ids).find_each do |group_participation|
          next if group_participation.user == current_user

          group_participation.destroy
        end
      end
      flash[:notice] = t('info.participations_destroyed')
    rescue ActiveRecord::ActiveRecordError
      flash[:error] = t('error.participations_destroyed')
    end

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

  def enable_content_landmark
    @content_landmark = true
  end

  def receiver_ids
    params.dig(:message, :receiver_ids).to_s.split(',')
  end

  def search_participant_params
    params[:search_participant] ? params.require(:search_participant).permit(:keywords, :role_id, :status_id) : {}
  end
end
