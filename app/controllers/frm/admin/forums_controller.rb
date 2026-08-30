module Frm
  module Admin
    class ForumsController < BaseController
      load_and_authorize_resource class: 'Frm::Forum', through: :group

      def index; end

      def new
        category = @group.categories.first
        @forum.category = category if category
        @forum.tags = category.tags if category
      end

      def edit; end

      def create
        if @forum.save
          create_successful
        else
          create_failed
        end
      end

      def update
        if @forum.update(forum_params)
          update_successful
        else
          update_failed
        end
      end

      def destroy
        @forum.destroy
        destroy_successful
      end

      private

      def forum_params
        permitted = params.require(:frm_forum).permit(
          :category_id, :title, :name, :description, :visible_outside, :tags_list, mod_ids: []
        )
        attributes = permitted.except(:category_id, :mod_ids).to_h
        attributes[:category] = @group.categories.find(permitted[:category_id]) if permitted[:category_id].present?
        attributes[:mods] = scoped_mods(permitted[:mod_ids]) if permitted.key?(:mod_ids)
        attributes
      end

      def scoped_mods(requested_ids)
        ids = Array(requested_ids).compact_blank.map(&:to_s).uniq
        mods = @group.mods.where(id: ids).to_a
        raise ActiveRecord::RecordNotFound unless mods.size == ids.size

        mods
      end

      def create_successful
        flash[:notice] = t('frm.admin.forum.created')
        redirect_to group_frm_admin_forums_url(@group), status: :see_other
      end

      def create_failed
        flash.now.alert = t('frm.admin.forum.not_created')
        render action: 'new', status: :unprocessable_content
      end

      def destroy_successful
        flash[:notice] = t('frm.admin.forum.deleted')
        redirect_to group_frm_admin_forums_url(@group), status: :see_other
      end

      def update_successful
        flash[:notice] = t('frm.admin.forum.updated')
        redirect_to group_frm_admin_forums_url(@group), status: :see_other
      end

      def update_failed
        flash.now.alert = t('frm.admin.forum.not_updated')
        render action: 'edit', status: :unprocessable_content
      end
    end
  end
end
