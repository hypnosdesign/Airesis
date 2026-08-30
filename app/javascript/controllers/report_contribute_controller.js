import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "commentId"]

  open(event) {
    event.preventDefault()
    this.commentIdTarget.value = event.currentTarget.dataset.commentId
    this.dialogTarget.showModal()
    requestAnimationFrame(() => this.dialogTarget.querySelector("input[name='reason']")?.focus())
  }

  close() {
    this.dialogTarget.close()
  }

  backdropClose(event) {
    if (event.target === this.dialogTarget) this.close()
  }
}
