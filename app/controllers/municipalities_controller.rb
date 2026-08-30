class MunicipalitiesController < ApplicationController
  before_action :authenticate_user!

  def index
    @territory = SysLocale.find_by(key: I18n.locale)&.territory || current_domain.territory
    query = params[:q].presence || params[:term].to_s
    @municipalities = @territory.municipalities.where(['lower_unaccent(description) like lower_unaccent(?)', query + '%']).order('population desc nulls last').limit(10)
    comuni = @municipalities.collect { |p| { id: p.id.to_s, text: p.description } }
    respond_to do |format|
      format.json { render json: comuni[0, 10] }
    end
  end
end
