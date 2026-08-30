import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "id", "list", "status"]
  static values = { url: String }

  connect() {
    this.timer = null
    this.abortController = null
  }

  disconnect() {
    clearTimeout(this.timer)
    this.abortController?.abort()
  }

  queueSearch() {
    clearTimeout(this.timer)
    this.idTarget.value = ""
    const query = this.queryTarget.value.trim()
    if (query.length < 2) {
      this.listTarget.replaceChildren()
      this.statusTarget.textContent = ""
      return
    }

    this.statusTarget.textContent = this.statusTarget.dataset.searching
    this.timer = setTimeout(() => this.search(query), 200)
  }

  select() {
    const option = Array.from(this.listTarget.options).find((item) => item.value === this.queryTarget.value)
    this.idTarget.value = option?.dataset.id || ""
    this.statusTarget.textContent = option ? this.statusTarget.dataset.selected : this.statusTarget.dataset.choose
  }

  async search(query) {
    this.abortController?.abort()
    this.abortController = new AbortController()

    try {
      const url = new URL(this.urlValue, window.location.origin)
      url.searchParams.set("q", query)
      const response = await fetch(url, {
        headers: { Accept: "application/json" },
        signal: this.abortController.signal,
      })
      if (!response.ok) throw new Error("municipality search failed")

      const municipalities = await response.json()
      if (this.queryTarget.value.trim() !== query) return

      this.listTarget.replaceChildren(...municipalities.map((municipality) => {
        const option = document.createElement("option")
        option.value = municipality.text
        option.dataset.id = municipality.id
        return option
      }))
      this.select()
      if (!this.idTarget.value) {
        this.statusTarget.textContent = municipalities.length > 0 ? this.statusTarget.dataset.choose : this.statusTarget.dataset.empty
      }
    } catch (error) {
      if (error.name !== "AbortError") this.statusTarget.textContent = this.statusTarget.dataset.error
    }
  }
}
