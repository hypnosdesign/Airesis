class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def change_notification_block
    respond_to_block change_block(current_user.blocked_alerts)
  end

  def change_email_notification_block
    respond_to_block change_block(current_user.blocked_emails)
  end

  def change_email_block
    respond_to_block current_user.update(receive_newsletter: params[:block] != 'true')
  end

  protected

  def change_block(alerts)
    if params[:block] == 'true'
      alerts.create(notification_type_id: params[:id])
    else
      alerts.find_by(notification_type_id: params[:id]).destroy
    end
  end

  def respond_to_block(result)
    if result
      flash[:notice] = t('info.setting_preferences')
    else
      flash[:error] = t('error.setting_preferences')
    end
    respond_to do |format|
      format.turbo_stream { render partial: 'layouts/flash_stream' }
      format.html { redirect_back fallback_location: root_path }
    end
  end
end
