import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["choice", "loading", "diff"]
  static values = { error: String }

  connect() {
    if (this.choiceTargets.some((choice) => choice.checked)) this.load()
  }

  async load() {
    const selected = this.choiceTargets.find((choice) => choice.checked)
    if (!selected) return

    this.loadingTarget.classList.remove("hidden")
    this.diffTarget.setAttribute("aria-busy", "true")

    try {
      const response = await fetch(selected.dataset.url, { headers: { Accept: "text/vnd.turbo-stream.html" } })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      window.Turbo.renderStreamMessage(await response.text())
    } catch (_error) {
      this.diffTarget.textContent = this.errorValue
    } finally {
      this.loadingTarget.classList.add("hidden")
      this.diffTarget.setAttribute("aria-busy", "false")
    }
  }
}
