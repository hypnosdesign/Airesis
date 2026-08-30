class QuorumsController < ApplicationController
  layout :choose_layout

  before_action :authenticate_user!
  before_action :use_content_landmark

  before_action :load_group, except: :help

  authorize_resource :group, except: :help

  load_and_authorize_resource class: 'BestQuorum', through: :group, shallow: true, parent: false, singleton: true, except: %i[index help]

  def index
    authorize! :index, BestQuorum
  end

  def new
    @page_title = t('pages.groups.edit_quorums.new_quorum.title')
    @quorum.attributes = { percentage: 0, good_score: 20, vote_percentage: 0, vote_good_score: 50 }
    @group_participations_count = @group.scoped_participants(:participate_proposals).count
    @vote_participants_count = @group.scoped_participants(:vote_proposals).count
    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  def create
    @quorum.public = false
    if @quorum.save
      flash[:notice] = t('info.quorums.quorum_created')
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to group_quorums_url(@group) }
      end
    else
      flash[:error] = t('error.quorums.quorum_creation')
      respond_to do |format|
        format.turbo_stream { render partial: 'layouts/flash_stream', status: :unprocessable_entity }
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @page_title = t('pages.groups.edit_quorums.edit_quorum')
    @group_participations_count = @group.scoped_participants(:participate_proposals).count
    @vote_participants_count = @group.scoped_participants(:vote_proposals).count
    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  def update
    if @quorum.update(best_quorum_params)
      flash[:notice] = t('info.quorums.quorum_updated')
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to group_quorums_url(@group) }
      end
    else
      flash[:error] = t('error.quorums.quorum_modification')
      respond_to do |format|
        format.turbo_stream { render partial: 'layouts/flash_stream', status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @quorum = @group.quorums.find(params[:id])
    @quorum.destroy
    flash[:notice] = t('info.quorums.quorum_deleted')
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to group_quorums_url(@group) }
    end
  end

  def change_status
    Quorum.transaction do
      @quorum = @group.quorums.find(params[:id])
      if params[:active] == 'true'
        @quorum.active = true
        flash[:notice] = t('info.quorums.quorum_activated')
      else
        @quorum.active = false
        flash[:notice] = t('info.quorums.quorum_deactivated')
      end
      @quorum.save!
    end
    respond_to do |format|
      format.turbo_stream { render partial: 'layouts/flash_stream' }
      format.html { redirect_back fallback_location: group_quorums_path(@group) }
    end
  end

  def help
    if params[:group_id]
      @group = Group.friendly.find(params[:group_id])
      authorize! :read, @group
      @quorums = @group.quorums.active
    else
      @quorums = Quorum.visible.active.all
    end
    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  protected

  def use_content_landmark
    @content_landmark = true
  end

  def best_quorum_params
    quorum_params
  end

  def quorum_params
    params.require(:best_quorum).permit(:id, :name, :description, :percentage, :valutations, :days_m, :hours_m,
                                        :minutes_m, :minutes, :good_score, :vote_percentage, :vote_good_score)
  end

  def choose_layout
    @group ? 'groups' : 'open_space'
  end
end
