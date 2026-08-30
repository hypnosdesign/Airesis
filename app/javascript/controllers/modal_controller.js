import { Controller } from "@hotwired/stimulus"

// Wraps a DaisyUI <dialog> element with showModal()/close().
// Usage:
//   <dialog data-controller="modal" data-modal-remove-on-close-value="true">
//     <div class="modal-box">
//       <button data-action="click->modal#close">X</button>
//       ...content...
//     </div>
//     <form method="dialog" class="modal-backdrop" data-action="click->modal#backdropClose">
//       <button>close</button>
//     </form>
//   </dialog>
export default class extends Controller {
  static targets = ["initialFocus"]

  static values = {
    removeOnClose: { type: Boolean, default: true },
    openOnConnect: { type: Boolean, default: true }
  }

  connect() {
    document.addEventListener("focusin", this._onDocumentFocusIn, true)
    this.openObserver = new MutationObserver(() => {
      if (this.element.open) this.focusInitialControl()
    })
    this.openObserver.observe(this.element, { attributes: true, attributeFilter: ["open"] })

    if (this.element.tagName === "DIALOG" && !this.element.open && this.openOnConnectValue) {
      this.element.showModal()
    }
    this.element.addEventListener("close", this._onClose)
    this.element.addEventListener("cancel", this._onCancel)
    this.element.addEventListener("keydown", this._onKeydown)
    if (this.element.open) this.focusInitialControl()
  }

  disconnect() {
    this.openObserver?.disconnect()
    this.element.removeEventListener("close", this._onClose)
    this.element.removeEventListener("cancel", this._onCancel)
    this.element.removeEventListener("keydown", this._onKeydown)
    document.removeEventListener("focusin", this._onDocumentFocusIn, true)
  }

  open() {
    if (this.element.tagName === "DIALOG") {
      this.element.showModal()
      this.focusInitialControl()
    }
  }

  close() {
    if (this.element.tagName === "DIALOG") {
      this.element.close()
    }
  }

  backdropClose(event) {
    if (event.target === this.element) {
      this.close()
    }
  }

  focusInitialControl() {
    const target = this.hasInitialFocusTarget
      ? this.initialFocusTarget
      : this.element.querySelector('button:not([disabled]), [href], input:not([disabled]), [tabindex]:not([tabindex="-1"])')
    if (!target) return

    // Opening a dialog changes its rendered visibility. Force that style change
    // before focusing, then repeat on the next frame as a browser fallback.
    this.element.getBoundingClientRect()
    target.focus({ preventScroll: true })
    requestAnimationFrame(() => {
      if (this.element.open && !this.element.contains(document.activeElement)) {
        target.focus({ preventScroll: true })
      }
    })
  }

  _onClose = () => {
    const returnTarget = this.returnFocusTarget
    if (this.removeOnCloseValue) {
      this.element.remove()
    }
    if (returnTarget?.isConnected) {
      returnTarget.focus({ preventScroll: true })
    }
  }

  _onDocumentFocusIn = (event) => {
    if (this.element.contains(event.target) || event.target === document.body) return
    this.returnFocusTarget = event.target
  }

  _onCancel = (event) => {
    event.preventDefault()
    this.close()
  }

  _onKeydown = (event) => {
    if (event.key === "Escape") {
      event.preventDefault()
      this.close()
      return
    }
    if (event.key !== "Tab") return

    const focusable = Array.from(this.element.querySelectorAll(
      'a[href], button:not([disabled]), input:not([disabled]):not([type="hidden"]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'
    )).filter((element) => element.offsetParent !== null)
    if (focusable.length === 0) return

    const first = focusable[0]
    const last = focusable[focusable.length - 1]
    if (!this.element.contains(document.activeElement)) {
      event.preventDefault()
      first.focus()
    } else if (event.shiftKey && document.activeElement === first) {
      event.preventDefault()
      last.focus()
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault()
      first.focus()
    }
  }
}
