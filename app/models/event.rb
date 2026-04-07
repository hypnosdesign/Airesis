# Un evento è un incontro fisico o una sessione di votazione collegata a proposte.
#
# Gli eventi di tipo `VOTATION` hanno un ciclo di vita speciale:
# - Al `create` vengono schedulati due job in Solid Queue: `STARTVOTATION` e `ENDVOTATION`
# - `start_votation` porta tutte le proposte collegate in stato VOTING
# - `end_votation` chiude il voto e calcola i risultati Schulze o standard
#
# Un evento può essere organizzato da uno o più gruppi (`MeetingOrganization`).
class Event < ApplicationRecord
  include FullCalendable

  # `proposal_id` è usato nel form di creazione per collegare direttamente una proposta all'evento.
  attr_accessor :period, :frequency, :commit_button, :proposal_id

  # == Validations

  validates :title, :starttime, :endtime, presence: true
  validates :description, presence: true, length: { maximum: 1.megabyte }
  validate :validate_start_time_end_time

  # == Associations

  belongs_to :user
  belongs_to :event_type
  has_many :proposals, class_name: 'Proposal', foreign_key: 'vote_period_id'
  has_many :possible_proposals, class_name: 'Proposal', foreign_key: 'vote_event_id'
  has_one :meeting, class_name: 'Meeting', inverse_of: :event, dependent: :destroy
  has_one :place, through: :meeting, class_name: 'Place'
  has_many :meeting_organizations, class_name: 'MeetingOrganization', foreign_key: 'event_id', dependent: :destroy
  has_many :groups, through: :meeting_organizations, class_name: 'Group', source: :group
  has_many :event_comments, class_name: 'EventComment', foreign_key: :event_id, dependent: :destroy

  delegate :meeting_participations, to: :meeting

  accepts_nested_attributes_for :meeting

  # == Callbacks

  before_validation :set_all_day_time

  include EventScopes

  after_destroy :remove_scheduled_tasks

  after_commit :send_notifications, on: :create

  # == Constants

  # Opzioni di ripetizione mostrate nel form (non ancora implementate lato business logic).
  REPEATS = ['Non ripetere',
             'Ogni giorno',
             'Ogni settimana',
             'Ogni mese',
             'Ogni anno'].freeze

  # == Instance Methods

  def valid_dates?
    starttime < endtime
  end

  def validate_start_time_end_time
    return unless starttime && endtime

    errors.add(:starttime, 'La data di inizio deve essere antecedente la data di fine') unless valid_dates?
  end

  # Durata dell'evento in secondi.
  #
  # @return [Float] secondi tra starttime e endtime
  def duration
    endtime - starttime
  end

  # Tempo rimanente alla fine dell'evento nella unità più leggibile (giorni/ore/minuti/secondi).
  # Restituisce nil se tutte le unità sono < 1 (evento terminato).
  #
  # @param ends_at [Time] riferimento temporale (default: now)
  # @return [String, nil] stringa localizzata o nil
  def time_left(ends_at = Time.zone.now)
    amount_seconds = endtime - ends_at # left in seconds
    amount_minutes = amount_seconds / 60.0
    amount_hours = amount_minutes / 60.0
    amount_days = amount_hours / 24.0
    values = [['days', amount_days], ['hours', amount_hours], ['minutes', amount_minutes], ['seconds', amount_seconds]]
    values.each do |unit|
      return I18n.t("time.left.#{unit[0]}", count: unit[1].to_i) if unit[1] >= 1
    end
  end

  def organizer_id=(id)
    meeting_organizations.build(group_id: id) if meeting_organizations.empty?
  end

  def organizer_id
    meeting_organizations.try(:first).try(:group_id)
  end

  def past?
    endtime < Time.zone.now
  end

  def now?
    starttime < Time.zone.now && endtime > Time.zone.now
  end

  def not_started?
    Time.zone.now < starttime
  end

  def votation?
    event_type_id == EventType::VOTATION
  end

  def meeting?
    event_type_id == EventType::MEETING
  end

  def validate
    errors.add_to_base('Start Time must be less than End Time') if (starttime >= endtime) && !all_day
  end

  def to_param
    "#{id}-#{title.downcase.gsub(/[^a-zA-Z0-9]+/, '-').gsub(/-{2,}/, '-').gsub(/^-|-$/, '')}"
  end

  # Avvia la votazione per tutte le proposte collegate all'evento.
  # Chiamato da `EventsWorker` (job schedulato all'allo scadere di `starttime`).
  #
  # @return [void]
  def start_votation
    proposals.each(&:start_votation)
  end

  # Chiude il voto e calcola i risultati per tutte le proposte collegate.
  # Chiamato da `EventsWorker` (job schedulato allo scadere di `endtime`).
  #
  # @return [void]
  def end_votation
    proposals.each(&:close_vote_phase)
  end

  def set_all_day_time
    return unless all_day

    self.starttime = starttime.beginning_of_day if starttime
    self.endtime = endtime.end_of_day if endtime
  end

  def formatted_starttime
    I18n.l starttime, format: all_day? ? :from_long_date : :from_long_date_time
  end

  def formatted_endtime
    I18n.l endtime, format: all_day? ? :until_long_date : :until_long_date_time
  end

  protected

  # Notifica la creazione dell'evento e, se è di tipo votazione,
  # schedula i job per avvio e chiusura del voto ai tempi esatti.
  # Usa `after_commit` per garantire che l'ID sia disponibile e il record sia committato.
  def send_notifications
    NotificationEventCreate.perform_later(id)

    # Solo gli eventi di votazione hanno un timer automatico; gli incontri sono gestiti manualmente
    return unless votation?

    EventsWorker.set(wait_until: starttime).perform_later('action' => EventsWorker::STARTVOTATION, 'event_id' => id)
    EventsWorker.set(wait_until: endtime).perform_later('action' => EventsWorker::ENDVOTATION, 'event_id' => id)
  end

  def remove_scheduled_tasks
  end
end
