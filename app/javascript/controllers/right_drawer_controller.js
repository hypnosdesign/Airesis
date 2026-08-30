import { Controller } from "@hotwired/stimulus"

// Right drawer per filtri (proposals/index, groups/index, ecc.)
// Trigger: <button data-action="right-drawer#open">Filtri</button>
// Il contenuto viene da content_for :left_panel nel layout.
export default class extends Controller {
  static targets = ["background", "close", "overlay", "panel", "trigger"]

  connect() {
    this.handleKeydown = this.handleKeydown.bind(this)
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown)
    document.body.classList.remove("overflow-hidden")
    if (this.hasBackgroundTarget) this.backgroundTarget.inert = false
  }

  open(event) {
    event?.preventDefault()
    if (!this.hasPanelTarget || !this.hasOverlayTarget) return

    this.previouslyFocused = event?.currentTarget || document.activeElement
    this.panelTarget.inert = false
    this.panelTarget.classList.remove("translate-x-full")
    this.panelTarget.setAttribute("aria-hidden", "false")
    this.overlayTarget.classList.remove("hidden")
    if (this.hasBackgroundTarget) {
      this.backgroundTarget.inert = true
      this.backgroundTarget.setAttribute("aria-hidden", "true")
    }
    this.triggerTargets.forEach((trigger) => trigger.setAttribute("aria-expanded", "true"))
    document.body.classList.add("overflow-hidden")
    document.addEventListener("keydown", this.handleKeydown)
    requestAnimationFrame(() => this.closeTarget?.focus())
  }

  close(event, restoreFocus = true) {
    event?.preventDefault()
    if (!this.hasPanelTarget || !this.hasOverlayTarget) return

    this.panelTarget.classList.add("translate-x-full")
    this.panelTarget.setAttribute("aria-hidden", "true")
    this.panelTarget.inert = true
    this.overlayTarget.classList.add("hidden")
    if (this.hasBackgroundTarget) {
      this.backgroundTarget.inert = false
      this.backgroundTarget.removeAttribute("aria-hidden")
    }
    this.triggerTargets.forEach((trigger) => trigger.setAttribute("aria-expanded", "false"))
    document.body.classList.remove("overflow-hidden")
    document.removeEventListener("keydown", this.handleKeydown)

    if (restoreFocus) {
      const focusTarget = this.previouslyFocused?.isConnected ? this.previouslyFocused : this.triggerTargets[0]
      if (focusTarget) {
        const restore = () => focusTarget.focus({ preventScroll: true })
        restore()
        requestAnimationFrame(restore)
      }
    }
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close(event)
      return
    }

    if (event.key !== "Tab") return

    const focusable = this.focusableElements
    if (focusable.length === 0) {
      event.preventDefault()
      return
    }

    const first = focusable[0]
    const last = focusable[focusable.length - 1]
    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault()
      last.focus()
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault()
      first.focus()
    }
  }

  get focusableElements() {
    if (!this.hasPanelTarget) return []

    return Array.from(this.panelTarget.querySelectorAll(
      'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'
    )).filter((element) => {
      const style = window.getComputedStyle(element)
      return !element.hidden &&
        style.display !== "none" &&
        style.visibility !== "hidden" &&
        element.getClientRects().length > 0 &&
        !element.closest('[inert], [aria-hidden="true"]')
    })
  }
}
