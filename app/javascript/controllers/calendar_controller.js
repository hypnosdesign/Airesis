import { Controller } from "@hotwired/stimulus"

// Wrapper Stimulus per FullCalendar v6.
// FullCalendar (~530KB) viene caricato solo quando il controller è attivo (lazy).
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
    todayLabel: { type: String, default: "today" },
    monthLabel: { type: String, default: "month" },
    weekLabel: { type: String, default: "week" },
    dayLabel: { type: String, default: "day" },
    listLabel: { type: String, default: "list" },
  }

  async connect() {
    this.mobileQuery = window.matchMedia("(max-width: 639px)")
    const [
      { Calendar },
      { default: dayGridPlugin },
      { default: timeGridPlugin },
      { default: listPlugin },
      { default: interactionPlugin }
    ] = await Promise.all([
      import("@fullcalendar/core"),
      import("@fullcalendar/daygrid"),
      import("@fullcalendar/timegrid"),
      import("@fullcalendar/list"),
      import("@fullcalendar/interaction")
    ])

    this.calendar = new Calendar(this.element, {
      plugins: [dayGridPlugin, timeGridPlugin, listPlugin, interactionPlugin],
      initialView: this.mobileQuery.matches ? "listWeek" : "timeGridWeek",
      locale: this.localeValue,
      height: "auto",
      headerToolbar: this.mobileQuery.matches ? {
        left: "prev,next",
        center: "title",
        right: "timeGridDay,listWeek",
      } : {
        left: "prev,next today",
        center: "title",
        right: "dayGridMonth,timeGridWeek,timeGridDay,listWeek",
      },
      buttonText: {
        today: this.todayLabelValue,
        month: this.monthLabelValue,
        week: this.weekLabelValue,
        day: this.dayLabelValue,
        list: this.listLabelValue,
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
        url.searchParams.set("has_time", info.allDay ? "false" : "true")
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
    this.#applyResponsiveView()

    this._handleViewportChange = () => this.#applyResponsiveView()
    this.mobileQuery.addEventListener("change", this._handleViewportChange)

    // Aggiorna il tema quando si fa toggle dark/light
    this._themeObserver = new MutationObserver(() => this.calendar.render())
    this._themeObserver.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ["data-theme"],
    })
  }

  disconnect() {
    this.mobileQuery?.removeEventListener("change", this._handleViewportChange)
    this._themeObserver?.disconnect()
    this.calendar?.destroy()
  }

  #applyResponsiveView() {
    const preferredView = this.mobileQuery.matches ? "listWeek" : "timeGridWeek"
    if (this.calendar.view.type !== preferredView) this.calendar.changeView(preferredView)
    this.element.dataset.calendarView = this.calendar.view.type
  }

  async #patchEvent(id, action, data, revert) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    try {
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
    } catch {
      revert()
    }
  }
}
