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
  static values = {
    removeOnClose: { type: Boolean, default: true }
  }

  connect() {
    if (this.element.tagName === "DIALOG" && !this.element.open) {
      this.element.showModal()
    }
    this.element.addEventListener("close", this._onClose)
  }

  disconnect() {
    this.element.removeEventListener("close", this._onClose)
  }

  open() {
    if (this.element.tagName === "DIALOG") {
      this.element.showModal()
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

  _onClose = () => {
    if (this.removeOnCloseValue) {
      this.element.remove()
    }
  }
}
