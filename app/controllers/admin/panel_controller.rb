require 'rake'

module Admin
  class PanelController < Admin::ApplicationController
    def show; end

    # calculate user rating
    def calculate_rankings
      AdminHelper.calculate_ranking
      flash[:notice] = 'OK'
      redirect_to admin_panel_path, status: :see_other
    end

    # change proposal states
    def change_proposals_state
      # check all proposals in debate and expired and close the debate
      Proposal.invalid_debate_phase.each(&:check_phase)

      # check all proposals waiting and put them in votation
      Proposal.invalid_waiting_phase.each do |proposal|
        EventsWorker.new.start_votation(proposal.vote_period.id)
      end

      # check all proposals in votation that has to be closed but are still in votation and the period has passed
      Proposal.invalid_vote_phase.each(&:close_vote_phase)

      flash[:notice] = 'Stato proposte aggiornato'
      redirect_to admin_panel_path, status: :see_other
    end

    def delete_old_notifications
      DeleteOldNotifications.perform_later
      flash[:notice] = t('admin_ui.panel.notifications_cleanup_queued')
      redirect_to admin_panel_path, status: :see_other
    end

    # invia una mail di prova tramite Solid Queue
    def test_mailer
      ResqueMailer.test_mail.deliver_later
      flash[:notice] = 'Test avviato'
      redirect_to admin_panel_path, status: :see_other
    end

    # invia una notifica di prova tramite resque e redis
    def test_notification
      if params[:alert_id].to_s != ''
        alert_id = params[:alert_id].to_i
        return redirect_to(admin_panel_path, alert: 'Alert non trovato', status: :see_other) unless Alert.exists?(alert_id)

        ResqueMailer.notification(alert_id).deliver_later
      else
        NotificationType.all.each do |type|
          notification = type.notifications.order('created_at desc').first
          alert = notification.alerts.first if notification
          ResqueMailer.notification(alert.id).deliver_later if alert
        end
      end
      flash[:notice] = 'Test avviato'
      redirect_to admin_panel_path, status: :see_other
    end

    # esegue un job di prova tramite resque_scheduler
    def test_scheduler
      ProposalsWorker.set(wait: 15.seconds).perform_later('proposal_id' => 1)
      flash[:notice] = 'Test avviato'
      redirect_to admin_panel_path, status: :see_other
    rescue StandardError => e
      Rails.logger.error("Scheduler test failed: #{e.class}")
      redirect_to admin_panel_path, alert: 'Il test dello scheduler non è stato avviato', status: :see_other
    end

    def write_sitemap
      Rails.application.load_tasks unless Rake::Task.task_defined?('sitemap:refresh')
      task = Rake::Task['sitemap:refresh']
      begin
        task.invoke
      ensure
        task.reenable
      end
      flash[:notice] = 'Sitemap aggiornata.'
      redirect_to admin_panel_path, status: :see_other
    end
  end
end
