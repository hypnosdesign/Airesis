import { Controller } from "@hotwired/stimulus"

// Infinite scroll using IntersectionObserver.
// Place a sentinel element at the bottom of the list:
//   <div data-controller="infinite-scroll"
//        data-infinite-scroll-url-value="/proposals?page=2">
//     <div data-infinite-scroll-target="sentinel"></div>
//   </div>
//
// When the sentinel enters the viewport, it fetches the next page as a
// Turbo Stream and updates the URL value for the subsequent page.
export default class extends Controller {
  static targets = ["sentinel"]
  static values = {
    url: String,
    loading: { type: Boolean, default: false }
  }

  connect() {
    this._observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting && !this.loadingValue && this.urlValue) {
            this._loadMore()
          }
        })
      },
      { rootMargin: "200px" }
    )

    if (this.hasSentinelTarget) {
      this._observer.observe(this.sentinelTarget)
    }
  }

  disconnect() {
    if (this._observer) this._observer.disconnect()
  }

  async _loadMore() {
    this.loadingValue = true

    try {
      const response = await fetch(this.urlValue, {
        headers: {
          Accept: "text/vnd.turbo-stream.html",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      if (!response.ok) return

      const html = await response.text()
      Turbo.renderStreamMessage(html)

      // If the response contains a next-page URL header, update for next load
      const nextPage = response.headers.get("X-Next-Page")
      this.urlValue = nextPage || ""

      if (!this.urlValue && this.hasSentinelTarget) {
        this.sentinelTarget.remove()
      }
    } finally {
      this.loadingValue = false
    }
  }
}
