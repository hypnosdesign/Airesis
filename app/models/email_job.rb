class EmailJob < ApplicationRecord
  belongs_to :alert
  validates :alert_id, presence: true
  validates :jid, presence: true, uniqueness: true

  def canceled!
    update(status: 3)
  end

  def completed?
    status == 2
  end

  def scheduled?
    status == 0
  end

  def completed!
    update(status: 2)
  end

  def scheduled_in_queue?
    SolidQueue::Job.find_by(active_job_id: jid)&.scheduled_execution.present?
  end

  def reschedule(new_time)
    SolidQueue::Job.find_by(active_job_id: jid)&.scheduled_execution&.update!(scheduled_at: new_time)
  end

  def accumulate
    nt = alert.notification_type
    delay = (nt.email_delay + nt.alert_delay).minutes
    if scheduled_in_queue?
      reschedule(delay.from_now)
    else
      Rails.logger.error('job not found when trying to accumulate on an existing email process')
    end
  end
end
