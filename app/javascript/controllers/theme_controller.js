import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.theme = localStorage.getItem("theme") || "nord"
    this.applyTheme()
  }

  toggle() {
    this.theme = this.theme === "nord" ? "night" : "nord"
    localStorage.setItem("theme", this.theme)
    this.applyTheme()
  }

  applyTheme() {
    this.element.setAttribute("data-theme", this.theme)
  }
}
