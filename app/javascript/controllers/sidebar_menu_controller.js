import { Controller } from "@hotwired/stimulus"

// Gestisce l'accordion submenu nella sidebar per i gruppi dell'utente.
// Espande/collassa con animazione max-height e ruota la freccia.
export default class extends Controller {
  static targets = ["submenu", "arrow"]
  static values = { open: Boolean }

  connect() {
    if (this.openValue) this.expand()
  }

  toggle() {
    this.openValue ? this.collapse() : this.expand()
  }

  expand() {
    this.openValue = true
    this.submenuTarget.style.maxHeight = this.submenuTarget.scrollHeight + "px"
    this.arrowTarget.classList.add("rotate-90")
  }

  collapse() {
    this.openValue = false
    this.submenuTarget.style.maxHeight = "0"
    this.arrowTarget.classList.remove("rotate-90")
  }
}
