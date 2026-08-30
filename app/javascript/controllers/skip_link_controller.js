import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  focusMain() {
    const target = document.querySelector(this.element.hash)
    requestAnimationFrame(() => target?.focus({ preventScroll: true }))
  }
}
