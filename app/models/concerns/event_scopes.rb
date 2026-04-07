# Scope per il filtraggio degli eventi, separati in un concern per mantenere `Event` leggibile.
# Incluso da `Event`.
module EventScopes
  extend ActiveSupport::Concern

  included do
    scope :visible, -> { where(private: false) }
    scope :not_visible, -> { where(private: true) }
    scope :votation, -> { where(event_type_id: EventType::VOTATION) }
    scope :after_time, ->(starttime = Time.zone.now) { where('starttime > ?', starttime) }
    # Periodi di votazione futuri, ordinati per data: usato nel form di scelta data voto.
    scope :vote_period, ->(starttime = Time.zone.now) { votation.after_time(starttime).order('starttime asc') }

    # Eventi non ancora terminati (endtime nel futuro).
    scope :next, -> { where(['endtime > ?', Time.zone.now]) }

    # Filtra gli eventi che si sovrappongono a una finestra temporale [starttime, endtime).
    # Un evento è incluso se il suo starttime O il suo endtime cade nell'intervallo.
    # Usa Arel per generare una condizione OR complessa senza SQL stringa.
    scope :time_scoped, (lambda do |starttime, endtime|
      event_t = Event.arel_table
      where(event_t[:starttime].gteq(starttime).and(event_t[:starttime].lt(endtime)).
          or(event_t[:endtime].gteq(starttime).and(event_t[:endtime].lt(endtime))))
    end)

    # Filtra gli eventi per territorio con logica polimorfica:
    # - Gli incontri (MEETING) vengono filtrati per il comune del luogo e i suoi antenati geografici
    # - Le votazioni (VOTATION) sono sempre incluse (non hanno un luogo fisico)
    #
    # Il campo usato per il JOIN varia in base al livello geografico del territorio:
    # Continent → continent_id, Country → country_id, Region → region_id, Province → province_id, Municipality → id
    scope :in_territory, (lambda do |territory|
      municipality_t = Municipality.arel_table
      event_t = Event.arel_table

      field = case territory
              when Continent then :continent_id
              when Country   then :country_id
              when Region    then :region_id
              when Province  then :province_id
              else                :id # Municipality
              end
      conditions = event_t[:event_type_id].eq(EventType::MEETING).and(municipality_t[field].eq(territory.id)).
          or(event_t[:event_type_id].eq(EventType::VOTATION))

      includes(:event_type, place: :municipality).references(:event_type, place: :municipality).where(conditions)
    end)
  end
end
