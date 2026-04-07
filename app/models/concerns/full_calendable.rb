# Fornisce metodi per esportare gli eventi nei formati iCalendar (.ics) e FullCalendar (JSON).
#
# Incluso da `Event`. Dipende dai campi `starttime`, `endtime`, `title`, `description`,
# `all_day`, `event_type` (con `color`) e dal metodo `votation?`.
#
# FullCalendar è la libreria JS usata per la vista calendario — `to_fc` produce
# il payload JSON atteso dalla sua API.
module FullCalendable
  extend ActiveSupport::Concern

  included do
  end

  # Formatta un Time nel formato iCalendar: `YYYYMMDDTHHmmss` (senza fuso orario — locale).
  #
  # @param time [Time]
  # @return [String]
  def ics_format(time)
    time.strftime('%Y%m%dT%H%M%S')
  end

  # @return [String] starttime in formato iCalendar
  def ics_starttime
    ics_format(starttime)
  end

  # @return [String] endtime in formato iCalendar
  def ics_endtime
    ics_format(endtime)
  end

  # @return [String] created_at in formato iCalendar
  def ics_created_at
    ics_format(created_at)
  end

  # @return [String] updated_at in formato iCalendar
  def ics_updated_at
    ics_format(updated_at)
  end

  # Colore di sfondo dell'evento nel calendario.
  # Fallback a blu chiaro (`#DFEFFC`) se il tipo evento non ha un colore configurato.
  #
  # @return [String] colore esadecimale
  def background_color
    event_type.color || '#DFEFFC'
  end

  # @return [String] colore testo fisso per contrasto su tutti i colori di sfondo
  def text_color
    '#333333'
  end

  # Serializza l'evento in un oggetto `Icalendar::Event` per l'export .ics.
  # L'URL usa la variabile ENV['SITE'] come base — configurarla in produzione.
  #
  # @return [Icalendar::Event]
  def to_ics
    event = Icalendar::Event.new
    event.dtstart = ics_starttime
    event.dtend = ics_endtime
    event.summary = title
    event.description = description
    event.created = ics_created_at
    event.last_modified = ics_updated_at
    event.uid = id.to_s
    event.url = "#{ENV['SITE']}/events/#{id}"
    event
  end

  # Serializza l'evento nel formato JSON atteso da FullCalendar.
  # Gli eventi di votazione non sono trascinabili (`editable: false`) per prevenire
  # modifiche accidentali delle date di voto.
  #
  # @return [Hash] payload FullCalendar
  def to_fc
    { id: id,
      title: title, description: description || 'Some cool description here...',
      start: starttime.iso8601.to_s, end: endtime.iso8601.to_s, allDay: all_day,
      recurring: false,
      backgroundColor: background_color, textColor: text_color, borderColor: Colors.darken_color(background_color),
      editable: !votation? } # le votazioni non devono essere spostate nel calendario
  end

  # Sposta l'evento di un delta in minuti e/o giorni (usato dal drag&drop di FullCalendar).
  #
  # @param minutes_delta [Integer] minuti da aggiungere a starttime e endtime
  # @param days_delta [Integer] giorni da aggiungere
  # @param all_day [Boolean, nil] se present sovrascrive il flag all_day
  # @return [Boolean] risultato del salvataggio
  def move(minutes_delta = 0, days_delta = 0, all_day = nil)
    self.starttime = minutes_delta.minutes.from_now(days_delta.days.from_now(starttime))
    self.endtime = minutes_delta.minutes.from_now(days_delta.days.from_now(endtime))
    self.all_day = all_day if all_day
    save
  end

  # Ridimensiona l'evento allungando/accorciando l'endtime (usato dal resize di FullCalendar).
  # Solo endtime viene modificato; starttime rimane invariato.
  #
  # @param minutes_delta [Integer] minuti da aggiungere a endtime
  # @param days_delta [Integer] giorni da aggiungere
  # @return [Boolean] risultato del salvataggio
  def resize(minutes_delta = 0, days_delta = 0)
    self.endtime = minutes_delta.minutes.from_now(days_delta.days.from_now(endtime))
    save
  end
end
