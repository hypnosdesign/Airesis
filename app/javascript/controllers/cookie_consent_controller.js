import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  accept() {
    const expires = new Date()
    expires.setFullYear(expires.getFullYear() + 1)
    document.cookie = `cookie_eu_consented=true; expires=${expires.toUTCString()}; path=/; SameSite=Lax`
    this.element.remove()
  }
}
