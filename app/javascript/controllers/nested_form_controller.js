import { Controller } from "@hotwired/stimulus"

// Handles nested form record removal (Rails _destroy pattern).
// Usage:
//   <div data-controller="nested-form">
//     <input type="checkbox" name="...[_destroy]" data-nested-form-target="destroy" style="display:none">
//     <a href="#" data-action="click->nested-form#remove">Remove</a>
//   </div>
export default class extends Controller {
  static targets = ["destroy"]

  remove(event) {
    event.preventDefault()
    if (this.hasDestroyTarget) {
      this.destroyTarget.value = "1"
      this.destroyTarget.checked = true
    }
    this.element.style.display = "none"
  }
}
