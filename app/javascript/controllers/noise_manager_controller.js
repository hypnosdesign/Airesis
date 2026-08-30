import { Controller } from "@hotwired/stimulus"

// Manages the noise panel for proposal comments with drag-and-drop and
// equivalent keyboard-operable controls.
// Collects sorted element IDs into hidden fields before form submission.
// Requires Sortable.js to be loaded (loaded via content_for :head in proposals/show).
export default class extends Controller {
  static targets = ["activeList", "inactiveList", "activeField", "inactiveField", "announcement"]

  connect() {
    if (typeof Sortable !== "undefined") {
      if (this.hasActiveListTarget) {
        Sortable.create(this.activeListTarget, { group: "noise", onAdd: event => this.updateButton(event.item) })
      }
      if (this.hasInactiveListTarget) {
        Sortable.create(this.inactiveListTarget, { group: "noise", onAdd: event => this.updateButton(event.item) })
      }
    }
  }

  toggle(event) {
    const button = event.currentTarget
    const item = button.closest("[data-id]")
    if (!item || !this.hasActiveListTarget || !this.hasInactiveListTarget) return

    const moveToInactive = this.activeListTarget.contains(item)
    const destination = moveToInactive ? this.inactiveListTarget : this.activeListTarget
    destination.append(item)
    this.updateButton(item)

    if (this.hasAnnouncementTarget) {
      this.announcementTarget.textContent = moveToInactive
        ? button.dataset.movedToInactiveAnnouncement
        : button.dataset.movedToActiveAnnouncement
    }
  }

  updateButton(item) {
    const button = item.querySelector("[data-action~='noise-manager#toggle']")
    if (!button) return

    const isActive = this.activeListTarget.contains(item)
    const label = isActive ? button.dataset.moveToInactiveLabel : button.dataset.moveToActiveLabel
    button.setAttribute("aria-label", label)
    const visibleLabel = button.querySelector("[data-noise-manager-label]")
    if (visibleLabel) visibleLabel.textContent = label
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
