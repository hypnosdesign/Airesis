import { Controller } from "@hotwired/stimulus"

// Generic toggle controller for show/hide, collapse/expand patterns.
// Usage:
//   <div data-controller="toggle">
//     <button data-action="click->toggle#toggle">Toggle</button>
//     <div data-toggle-target="content">Hidden content</div>
//   </div>
export default class extends Controller {
  static targets = ["content"]
  static values = {
    open: { type: Boolean, default: false }
  }

  connect() {
    this._apply()
  }

  toggle() {
    this.openValue = !this.openValue
    this._apply()
  }

  show() {
    this.openValue = true
    this._apply()
  }

  hide() {
    this.openValue = false
    this._apply()
  }

  _apply() {
    if (this.hasContentTarget) {
      this.contentTarget.style.display = this.openValue ? "" : "none"
    }
  }
}
