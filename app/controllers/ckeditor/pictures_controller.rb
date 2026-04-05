class Ckeditor::PicturesController < Ckeditor::ApplicationController
  respond_to :html

  def index
    pictures = Ckeditor.picture_adapter.find_all(ckeditor_pictures_scope(assetable_id: ckeditor_current_user))
    @pagy, @pictures = pagy_array(pictures.to_a)
    first_page = @pagy.page == 1

    respond_with(@pictures, layout: first_page)
  end

  def create
    @picture = Ckeditor.picture_model.new
    respond_with_asset(@picture)
  end

  def destroy
    @picture.destroy
    respond_with(@picture, location: pictures_path)
  end

  protected

  def find_asset
    @picture = Ckeditor.picture_adapter.get!(params[:id])
  end

  def authorize_resource
    model = (@picture || Ckeditor.picture_model)
    @authorization_adapter.try(:authorize, params[:action], model)
  end
end
