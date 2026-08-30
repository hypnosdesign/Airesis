class ProposalCategoriesController < ApplicationController
  def index
    @proposalcategories = ProposalCategory.order(id: :desc)

    respond_to do |format|
      format.json { render json: @proposalcategories.as_json(only: :id, methods: :description) }
    end
  end
end
