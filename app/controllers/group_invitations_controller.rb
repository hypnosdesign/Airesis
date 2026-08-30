# invite other users in the group
class GroupInvitationsController < ApplicationController
  layout 'groups'

  before_action :enable_content_landmark
  before_action :authenticate_user!

  load_and_authorize_resource :group
  load_and_authorize_resource through: :group

  def new
    respond_to do |format|
      format.html do
        @page_title = t('pages.groups.invite_your_friends.title')
      end
      format.turbo_stream
    end
  end

  def create
    @group_invitation.inviter = current_user
    if @group_invitation.save
      respond_to do |format|
        flash[:notice] = t('info.group_invitations.create',
                           count: @group_invitation.group_invitation_emails.count,
                           email_addresses: @group_invitation.group_invitation_emails.pluck(:email).join(', '))
        format.turbo_stream { redirect_to @group, status: :see_other }
        format.html { redirect_to @group }
      end
    else
      @page_title = t('pages.groups.invite_your_friends.title')
      flash.now[:error] = t('error.group_invitations.create')
      respond_to do |format|
        format.turbo_stream { render :new, status: :unprocessable_content }
        format.html { render :new, status: :unprocessable_content }
      end
    end
  end

  protected

  def enable_content_landmark
    @content_landmark = true
  end

  def group_invitation_params
    params.require(:group_invitation).permit(:emails_list, :testo)
  end
end
