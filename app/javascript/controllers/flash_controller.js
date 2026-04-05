import { Controller } from "@hotwired/stimulus"

// Replaces toastr.js for flash messages using DaisyUI toast component.
// Usage: <div data-controller="flash" data-flash-type-value="success" data-flash-auto-dismiss-value="5000">
//          <span data-flash-target="message">Message text</span>
//        </div>
export default class extends Controller {
  static targets = ["message"]
  static values = {
    type: { type: String, default: "info" },
    autoDismiss: { type: Number, default: 5000 }
  }

  connect() {
    if (this.autoDismissValue > 0) {
      this.timeout = setTimeout(() => this.dismiss(), this.autoDismissValue)
    }
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
  }

  dismiss() {
    this.element.classList.add("opacity-0", "transition-opacity", "duration-300")
    setTimeout(() => this.element.remove(), 300)
  }

  // Maps flash key to DaisyUI alert class
  get alertClass() {
    const map = {
      info: "alert-info",
      notice: "alert-success",
      success: "alert-success",
      warn: "alert-warning",
      warning: "alert-warning",
      error: "alert-error",
      alert: "alert-error"
    }
    return map[this.typeValue] || "alert-info"
  }
}
