import { Controller } from "@hotwired/stimulus"

// Manages the noise panel drag-and-drop for proposal comments.
// Collects sorted element IDs into hidden fields before form submission.
// Requires Sortable.js to be loaded (loaded via content_for :head in proposals/show).
export default class extends Controller {
  static targets = ["activeList", "inactiveList", "activeField", "inactiveField"]

  connect() {
    if (typeof Sortable !== "undefined") {
      if (this.hasActiveListTarget) {
        Sortable.create(this.activeListTarget, { group: "noise" })
      }
      if (this.hasInactiveListTarget) {
        Sortable.create(this.inactiveListTarget, { group: "noise" })
      }
    }
  }

  collectIds(event) {
    if (this.hasActiveListTarget && this.hasActiveFieldTarget) {
      const ids = Array.from(this.activeListTarget.querySelectorAll("[data-id]"))
        .map(el => el.dataset.id)
      this.activeFieldTarget.value = ids.join(",")
    }
    if (this.hasInactiveListTarget && this.hasInactiveFieldTarget) {
      const ids = Array.from(this.inactiveListTarget.querySelectorAll("[data-id]"))
        .map(el => el.dataset.id)
      this.inactiveFieldTarget.value = ids.join(",")
    }
  }
}
