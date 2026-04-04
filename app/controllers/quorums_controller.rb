class QuorumsController < ApplicationController
  layout :choose_layout

  before_action :authenticate_user!

  before_action :load_group, except: :help

  authorize_resource :group

  load_and_authorize_resource class: 'BestQuorum', through: :group, shallow: true, parent: false, singleton: true, except: [:index]

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
    @quorum = @group.quorums.find_by(id: params[:id])
    @quorum.destroy
    flash[:notice] = t('info.quorums.quorum_deleted')
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to group_quorums_url(@group) }
    end
  end

  def change_status
    Quorum.transaction do
      quorum = @group.quorums.find_by(id: params[:id])
      if quorum
        if params[:active] == 'true'
          quorum.active = true
          flash[:notice] = t('info.quorums.quorum_activated')
        else
          quorum.active = false
          flash[:notice] = t('info.quorums.quorum_deactivated')
        end
        quorum.save!
      end
    end
    respond_to do |format|
      format.turbo_stream { render partial: 'layouts/flash_stream' }
      format.html { redirect_back fallback_location: group_quorums_path(@group) }
    end
  end

  def dates
    starttime = (@quorum.minutes.minutes + DEBATE_VOTE_DIFFERENCE).from_now
    @dates = if @group
               @group.events.not_visible.vote_period(starttime).collect { |p| ["da #{l p.starttime} a #{l p.endtime}", p.id, { 'data-start' => (l p.starttime), 'data-end' => (l p.endtime), 'data-title' => p.title }] }
             else
               Event.visible.vote_period(starttime).collect { |p| ["da #{l p.starttime} a #{l p.endtime}", p.id] }
             end
    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  def help
    if params[:group_id]
      @group = Group.find(params[:group_id])
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
