module Frm
  module Admin
    class CategoriesController < BaseController
      load_and_authorize_resource class: 'Frm::Category', through: :group

      def index; end

      def new
        respond_to do |format|
          format.turbo_stream
          format.html
        end
      end

      def create
        if @category.save
          @categories = @group.categories
          flash[:notice] = t('frm.admin.category.created')
          respond_to do |format|
            format.turbo_stream
            format.html { redirect_to group_frm_admin_categories_url(@group) }
          end
        else
          flash.now.alert = t('frm.admin.category.not_created')
          render action: :new, status: :unprocessable_entity
        end
      end

      def edit
        respond_to do |format|
          format.turbo_stream
          format.html
        end
      end

      def update
        if @category.update(category_params)
          @categories = @group.categories
          flash[:notice] = t('frm.admin.category.updated')
          respond_to do |format|
            format.turbo_stream
            format.html { redirect_to group_frm_admin_categories_url(@group) }
          end
        else
          flash.now.alert = t('frm.admin.category.not_updated')
          respond_to do |format|
            format.turbo_stream { render :edit }
            format.html { render action: :edit, status: :unprocessable_entity }
          end
        end
      end

      def destroy
        @category.destroy
        @categories = @group.categories
        flash[:notice] = t('frm.admin.category.deleted')
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to group_frm_admin_categories_url(@group) }
        end
      end

      protected

      def category_params
        params.require(:frm_category).permit(:name, :visible_outside, :tags_list)
      end
    end
  end
end
