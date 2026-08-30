module Admin
  class UsersController < Admin::ManagerController
    include UsersHelper

    def block
      @user = find_target_user!
      return protected_user if @user == current_user || @user.moderator?

      unless @user.blocked?
        User.transaction do
          @user.update!(blocked: true, blocked_name: @user.name, blocked_surname: @user.surname,
                        name: 'Utente', surname: 'Eliminato')
          @user.avatar.purge_later if @user.avatar.attached?
          ResqueMailer.blocked(@user.id).deliver_later
        end
      end
      flash[:notice] = t('info.moderator_panel.account_blocked')
      redirect_back fallback_location: moderator_panel_path, status: :see_other
    end

    def unblock
      @user = User.find(params.expect(:id).to_s[/\A\d+/])
      if @user.blocked?
        @user.update!(blocked: false, name: @user.blocked_name, surname: @user.blocked_surname,
                      blocked_name: nil, blocked_surname: nil)
      end
      flash[:notice] = t('info.moderator_panel.account_unblocked')
      redirect_back fallback_location: moderator_panel_path, status: :see_other
    end

    # admin user autocomplete
    def autocomplete
      users = User.autocomplete(params[:term]).unblocked.user_type_id_authenticated
      users = users.map do |u|
        { id: u.id, identifier: "#{u.surname} #{u.name}", name: u.name.to_s, surname: u.surname.to_s,
          image_path: view_context.avatar(u, size: 20).to_s }
      end
      render json: users
    end

    private

    def find_target_user!
      identifier = params.expect(:user_id)
      User.find_by(id: identifier) || User.find_by!(email: identifier.to_s.strip.downcase)
    end

    def protected_user
      redirect_back fallback_location: moderator_panel_path,
                    alert: t('info.moderator_panel.privileged_account'), status: :see_other
    end
  end
end
