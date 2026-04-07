import { Controller } from "@hotwired/stimulus"
import { Calendar } from "@fullcalendar/core"
import dayGridPlugin from "@fullcalendar/daygrid"
import timeGridPlugin from "@fullcalendar/timegrid"
import listPlugin from "@fullcalendar/list"
import interactionPlugin from "@fullcalendar/interaction"

// Wrapper Stimulus per FullCalendar v6.
// Dati passati via data-values:
//   data-calendar-events-url-value  — URL JSON endpoint eventi
//   data-calendar-new-event-url-value — URL form nuovo evento (opzionale)
//   data-calendar-locale-value      — es. 'it'
//   data-calendar-editable-value    — true/false (drag & resize)
export default class extends Controller {
  static values = {
    eventsUrl: String,
    newEventUrl: String,
    locale: { type: String, default: "it" },
    editable: { type: Boolean, default: false },
  }

  connect() {
    this.calendar = new Calendar(this.element, {
      plugins: [dayGridPlugin, timeGridPlugin, listPlugin, interactionPlugin],
      initialView: "timeGridWeek",
      locale: this.localeValue,
      height: "auto",
      headerToolbar: {
        left: "prev,next today",
        center: "title",
        right: "dayGridMonth,timeGridWeek,timeGridDay,listWeek",
      },
      buttonText: {
        today: "oggi",
        month: "mese",
        week: "settimana",
        day: "giorno",
        list: "lista",
      },
      firstDay: 1, // lunedì
      slotMinTime: "07:00:00",
      slotMaxTime: "22:00:00",
      events: this.eventsUrlValue,
      editable: this.editableValue,          // drag & resize eventi esistenti
      selectable: !!this.newEventUrlValue,   // drag su slot vuoto per creare
      selectMirror: true,

      // Click su evento → naviga
      eventClick: (info) => {
        if (info.event.url) {
          info.jsEvent.preventDefault()
          Turbo.visit(info.event.url)
        }
      },

      // Singolo click su slot vuoto → form nuovo evento
      dateClick: (info) => {
        if (!this.newEventUrlValue) return
        const url = new URL(this.newEventUrlValue, window.location.origin)
        url.searchParams.set("starttime", info.date.getTime())
        url.searchParams.set("endtime", info.date.getTime() + 3600000) // +1h default
        url.searchParams.set("has_time", info.allDay ? "false" : "true")
        Turbo.visit(url.toString())
      },

      // Drag su slot vuoto → form con intervallo esatto
      select: (info) => {
        if (!this.newEventUrlValue) return
        const url = new URL(this.newEventUrlValue, window.location.origin)
        url.searchParams.set("starttime", info.start.getTime())
        url.searchParams.set("endtime", info.end.getTime())
        url.searchParams.set("has_time", !info.allDay)
        Turbo.visit(url.toString())
      },

      // Drag → POST :move
      eventDrop: (info) => {
        const delta = info.delta
        this.#patchEvent(info.event.id, "move", {
          day_delta: delta.days,
          minute_delta: (delta.hours * 60) + (delta.minutes),
          all_day: info.event.allDay,
        }, info.revert)
      },

      // Resize → POST :resize
      eventResize: (info) => {
        const delta = info.endDelta
        this.#patchEvent(info.event.id, "resize", {
          day_delta: delta.days,
          minute_delta: (delta.hours * 60) + (delta.minutes),
        }, info.revert)
      },
    })
    this.calendar.render()

    // Aggiorna il tema quando si fa toggle dark/light
    this._themeObserver = new MutationObserver(() => this.calendar.render())
    this._themeObserver.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ["data-theme"],
    })
  }

  disconnect() {
    this._themeObserver?.disconnect()
    this.calendar?.destroy()
  }

  async #patchEvent(id, action, data, revert) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    const response = await fetch(`/events/${id}/${action}`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify(data),
    })
    if (!response.ok) revert()
  }
}
