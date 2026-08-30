class ProposalRevisionsController < ApplicationController
  layout :choose_layout

  before_action :authenticate_user!
  before_action :use_content_landmark

  load_and_authorize_resource :proposal
  load_resource through: :proposal

  def index
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to proposal_proposal_revisions_path(@proposal) }
    end
  end

  protected

  def use_content_landmark
    @content_landmark = true
  end

  def choose_layout
    @proposal.private ? 'groups' : 'open_space'
  end
end
