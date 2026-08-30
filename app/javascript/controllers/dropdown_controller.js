import { Controller } from "@hotwired/stimulus"

// Accessible state and keyboard handling for DaisyUI dropdown popovers.
export default class extends Controller {
  static targets = ["content", "trigger"]

  connect() {
    this.handleDocumentClick = (event) => {
      if (!this.element.contains(event.target)) this.close()
    }
    document.addEventListener("click", this.handleDocumentClick)
    this.setOpen(false)
  }

  disconnect() {
    document.removeEventListener("click", this.handleDocumentClick)
  }

  toggle(event) {
    event.preventDefault()
    this.setOpen(!this.isOpen)
  }

  keydown(event) {
    if (event.key === "Escape") {
      event.preventDefault()
      this.close(true)
    } else if (event.key === "ArrowDown" && event.target === this.triggerTarget) {
      event.preventDefault()
      this.setOpen(true)
      this.focusFirstItem()
    }
  }

  focusout() {
    requestAnimationFrame(() => {
      if (!this.element.contains(document.activeElement)) this.close()
    })
  }

  close(restoreFocus = false) {
    if (!this.isOpen) return

    this.setOpen(false)
    if (restoreFocus) this.triggerTarget.focus({ preventScroll: true })
  }

  setOpen(open) {
    this.isOpen = open
    this.element.classList.toggle("dropdown-open", open)
    this.triggerTarget.setAttribute("aria-expanded", String(open))
    this.contentTarget.setAttribute("aria-hidden", String(!open))
  }

  focusFirstItem() {
    requestAnimationFrame(() => {
      const target = this.contentTarget.querySelector("a[href], button:not([disabled]), [tabindex]:not([tabindex='-1'])")
      target?.focus({ preventScroll: true })
    })
  }
}
