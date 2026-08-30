class AnnouncementsController < ApplicationController
  load_and_authorize_resource

  def hide
    ids = [params[:id], *Array(cookies.signed[:hidden_announcement_ids])].map(&:to_s).uniq.first(50)
    cookies.permanent.signed[:hidden_announcement_ids] = ids
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: root_path }
    end
  end
end
