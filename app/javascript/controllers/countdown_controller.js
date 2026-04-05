import { Controller } from "@hotwired/stimulus"

// Renders a live countdown from a Unix timestamp.
// Usage:
//   <span data-controller="countdown"
//         data-countdown-end-at-value="1712345678"
//         data-countdown-expired-text-value="Votazione chiusa">
//   </span>
export default class extends Controller {
  static values = {
    endAt: Number,
    expiredText: { type: String, default: "" }
  }

  connect() {
    this._update()
    this._interval = setInterval(() => this._update(), 1000)
  }

  disconnect() {
    if (this._interval) clearInterval(this._interval)
  }

  _update() {
    const now = Math.floor(Date.now() / 1000)
    const remaining = this.endAtValue - now

    if (remaining <= 0) {
      this.element.textContent = this.expiredTextValue
      clearInterval(this._interval)
      this.dispatch("expired")
      return
    }

    const days = Math.floor(remaining / 86400)
    const hours = Math.floor((remaining % 86400) / 3600)
    const minutes = Math.floor((remaining % 3600) / 60)
    const seconds = remaining % 60

    const parts = []
    if (days > 0) parts.push(`${days}g`)
    if (hours > 0 || days > 0) parts.push(`${hours}h`)
    parts.push(`${String(minutes).padStart(2, "0")}m`)
    parts.push(`${String(seconds).padStart(2, "0")}s`)

    this.element.textContent = parts.join(" ")
  }
}
