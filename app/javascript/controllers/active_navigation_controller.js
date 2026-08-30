import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["active"]

  connect() {
    requestAnimationFrame(() => this.revealActiveItem())
  }

  revealActiveItem() {
    if (!this.hasActiveTarget || this.element.scrollWidth <= this.element.clientWidth) return

    const item = this.activeTarget
    const itemStart = item.offsetLeft
    const itemEnd = itemStart + item.offsetWidth
    const visibleStart = this.element.scrollLeft
    const visibleEnd = visibleStart + this.element.clientWidth

    if (itemStart >= visibleStart && itemEnd <= visibleEnd) return

    const centeredPosition = itemStart - (this.element.clientWidth - item.offsetWidth) / 2
    this.element.scrollTo({ left: Math.max(centeredPosition, 0), behavior: "auto" })
  }
}
