import { Controller } from "@hotwired/stimulus"

// Keeps the DaisyUI drawer checkbox and the visible navigation controls in sync.
// The checkbox remains the CSS state source; real buttons provide keyboard focus.
export default class extends Controller {
  static targets = ["background", "checkbox", "close", "dialog", "panel", "toggle"]

  connect() {
    this.mobileQuery = window.matchMedia("(max-width: 1023px)")
    this.handleViewportChange = () => this.sync()
    this.handleKeydown = (event) => this.onKeydown(event)
    this.mobileQuery.addEventListener("change", this.handleViewportChange)
    document.addEventListener("keydown", this.handleKeydown)
    this.wasOpen = false
    if (this.hasRequiredTargets()) this.sync()
  }

  disconnect() {
    this.mobileQuery?.removeEventListener("change", this.handleViewportChange)
    document.removeEventListener("keydown", this.handleKeydown)
    this.cancelFocusRetry()
    this.releaseBackground()
  }

  toggle(event) {
    event?.preventDefault()
    if (!this.hasRequiredTargets()) return

    this.returnFocusTarget = event?.currentTarget || this.toggleTarget
    this.checkboxTarget.checked = !this.checkboxTarget.checked
    this.sync()
  }

  close(event) {
    event?.preventDefault()
    if (!this.hasRequiredTargets()) return

    this.checkboxTarget.checked = false
    this.sync()
    this.returnFocusTarget?.focus()
  }

  sync() {
    if (!this.hasRequiredTargets()) return

    const isOpen = this.checkboxTarget.checked
    const isModal = this.mobileQuery.matches && isOpen

    this.toggleTargets.forEach((button) => {
      button.setAttribute("aria-expanded", String(isOpen))
      button.setAttribute("aria-label", isOpen ? button.dataset.closeLabel : button.dataset.openLabel)
    })

    this.panelTarget.setAttribute("aria-hidden", String(this.mobileQuery.matches && !isOpen))
    this.dialogTarget.setAttribute("role", isModal ? "dialog" : "navigation")
    if (isModal) {
      // DaisyUI keeps the closed drawer visibility-hidden. Make the panel
      // focusable in the same task that opens it, before the next paint.
      this.panelTarget.style.visibility = "visible"
      this.dialogTarget.style.visibility = "visible"
      this.dialogTarget.setAttribute("aria-modal", "true")
      this.isolateBackground()
      document.body.classList.add("overflow-hidden")
    } else {
      this.cancelFocusRetry()
      this.panelTarget.style.removeProperty("visibility")
      this.dialogTarget.style.removeProperty("visibility")
      this.dialogTarget.removeAttribute("aria-modal")
      this.releaseBackground()
    }

    if (isModal && !this.wasOpen) {
      // The sidebar animates from zero width on its first opening. Keep checking
      // for a bounded number of frames so focus lands after it becomes visible.
      this.dialogTarget.getBoundingClientRect()
      this.focusRetryCount = 0
      this.focusCloseControl()
    }
    this.wasOpen = isOpen
  }

  onKeydown(event) {
    if (!this.mobileQuery.matches || !this.checkboxTarget.checked) return

    if (event.key === "Escape") {
      event.preventDefault()
      this.close()
      return
    }

    if (event.key !== "Tab") return
    const focusable = Array.from(this.dialogTarget.querySelectorAll(
      'a[href], button:not([disabled]), input:not([disabled]):not([type="hidden"]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'
    )).filter((element) => element.offsetParent !== null)
    if (focusable.length === 0) return

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

  releaseBackground() {
    if (this.hasBackgroundTarget) {
      this.backgroundElements().forEach((element) => {
        element.inert = false
        element.removeAttribute("aria-hidden")
      })
    }
    document.body.classList.remove("overflow-hidden")
  }

  isolateBackground() {
    this.backgroundElements().forEach((element) => {
      element.inert = true
      element.setAttribute("aria-hidden", "true")
    })
  }

  backgroundElements() {
    if (!this.hasBackgroundTarget) return []

    return [
      this.backgroundTarget,
      ...this.backgroundTarget.querySelectorAll("nav, main, footer")
    ]
  }

  focusCloseControl() {
    if (!this.mobileQuery.matches || !this.checkboxTarget.checked) {
      this.cancelFocusRetry()
      return
    }

    if (!this.dialogTarget.contains(document.activeElement)) {
      this.closeTarget.focus({ preventScroll: true })
    }

    this.focusRetryCount += 1
    const focusIsStable = this.dialogTarget.contains(document.activeElement) && this.focusRetryCount >= 2
    if (focusIsStable || this.focusRetryCount >= 40) {
      this.cancelFocusRetry()
      return
    }

    this.focusRetryFrame = requestAnimationFrame(() => this.focusCloseControl())
  }

  cancelFocusRetry() {
    if (this.focusRetryFrame) cancelAnimationFrame(this.focusRetryFrame)
    this.focusRetryFrame = null
  }

  hasRequiredTargets() {
    return this.hasCheckboxTarget && this.hasPanelTarget && this.hasDialogTarget && this.hasCloseTarget
  }
}
