import { Controller } from "@hotwired/stimulus"

// Right drawer per filtri (proposals/index, groups/index, ecc.)
// Trigger: <button data-action="right-drawer#open">Filtri</button>
// Il contenuto viene da content_for :left_panel nel layout.
export default class extends Controller {
  static targets = ["overlay"]

  open() {
    this.element.classList.remove("translate-x-full")
    this.element.setAttribute("aria-hidden", "false")
    this.overlayTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  close() {
    this.element.classList.add("translate-x-full")
    this.element.setAttribute("aria-hidden", "true")
    this.overlayTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }
}
