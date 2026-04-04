class ProposalRevisionsController < ApplicationController
  layout :choose_layout

  before_action :authenticate_user!

  load_and_authorize_resource :proposal
  load_resource through: :proposal

  def index
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show; end

  protected

  def choose_layout
    @proposal.private ? 'groups' : 'open_space'
  end
end
