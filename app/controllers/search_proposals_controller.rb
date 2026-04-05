class SearchProposalsController < ApplicationController
  def create
    search = SearchProposal.new(params[:search_proposal])
    @pagy, @proposals = pagy(search.results, items: search.per_page || 10)
    flash[:notice] = t('info.groups.search_proposal')
    respond_to do |format|
      format.html
    end
  end
end
