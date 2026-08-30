import { Controller } from "@hotwired/stimulus"

// Opens an existing dialog without inline JavaScript or placeholder links.
export default class extends Controller {
  static values = { dialogId: String }

  open(event) {
    event.preventDefault()
    const dialog = document.getElementById(this.dialogIdValue)
    if (dialog?.showModal && !dialog.open) dialog.showModal()
  }
}
