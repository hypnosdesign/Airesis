class ProposalSupportsController < ApplicationController
  # load_and_authorize_resource
  layout :choose_layout

  before_action :load_proposal

  authorize_resource only: [:new]

  before_action :authenticate_user!
  before_action :use_content_landmark

  def new
    @proposal_support = @proposal.proposal_supports.build
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def create
    authorize! :create, ProposalSupport
    # the user must have the correct permissions on each group

    # required groups
    groups = begin
               params[:proposal][:supporting_group_ids].collect(&:to_i)
             rescue StandardError
               []
             end
    # his groups
    user_groups = current_user.scoped_group_participations(:support_proposals).pluck('group_participations.group_id')

    # allowed groups
    diff = groups - user_groups

    raise ActiveRecord::ActiveRecordError unless diff.empty?

    no_supp = user_groups - groups # id of user groups not supported

    @proposal.supporting_group_ids += groups
    @proposal.supporting_group_ids -= no_supp

    @proposal.save!
    flash[:notice] = t('info.proposal_supports.saved', default: 'Proposal support was saved.')

    respond_to do |format|
      format.html do
        redirect_to @proposal
      end
      format.turbo_stream
    end
  rescue ActiveRecord::ActiveRecordError
    flash[:error] = t('error.proposal_supports.save', default: 'Proposal support could not be saved.')
    respond_to do |format|
      format.html { redirect_to proposal_path(@proposal) }
      format.turbo_stream { render partial: 'layouts/flash_stream', status: :unprocessable_entity }
    end
  end

  protected

  def choose_layout
    @proposal.private? ? 'groups' : 'open_space'
  end

  def use_content_landmark
    @content_landmark = true
  end

  def load_proposal
    @proposal = Proposal.find(params[:proposal_id])
  end
end
