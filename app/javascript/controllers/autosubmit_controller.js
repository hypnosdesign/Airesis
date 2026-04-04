import { Controller } from "@hotwired/stimulus"

// Auto-submits a form when an input changes (for filters, search, etc.)
// Usage:
//   <form data-controller="autosubmit">
//     <select data-action="change->autosubmit#submit">...</select>
//   </form>
export default class extends Controller {
  static values = {
    delay: { type: Number, default: 300 }
  }

  submit() {
    clearTimeout(this._timeout)
    this._timeout = setTimeout(() => {
      this.element.requestSubmit()
    }, this.delayValue)
  }
}
