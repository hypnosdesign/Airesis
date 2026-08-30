module Frm
  module Admin
    class MembersController < BaseController
      def add
        user = User.find_by(id: params[:frm_user_id])
        if user.nil?
          flash[:alert] = t('frm.admin.mods.show.member_not_found')
        elsif !group.members.exists?(user.id)
          flash[:notice] = t('info.members.ok_message')
          group.members << user
        end
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to group_frm_admin_mod_url(@group, group), status: :see_other }
        end
      end

      private

      def group
        @frm_mod ||= @group.mods.find(params.expect(:mod_id))
      end
    end
  end
end
