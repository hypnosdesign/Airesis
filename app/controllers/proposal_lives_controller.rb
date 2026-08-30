class ProposalLivesController < ApplicationController
  # load_and_authorize_resource
  # carica la proposta
  before_action :load_proposal

  # ##SICUREZZA###

  # l'utente deve aver fatto login
  before_action :authenticate_user!
  before_action :authorize_proposal

  def show
    @life = @proposal.proposal_lives.find(params[:id])
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to proposal_proposal_revisions_path(@proposal) }
    end
  end

  protected

  def load_proposal
    @proposal = Proposal.find(params[:proposal_id])
    @group = @proposal.groups.first if @proposal.private
  end

  def authorize_proposal
    authorize! :read, @proposal
  end
end
