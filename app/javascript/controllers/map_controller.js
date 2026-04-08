import { Controller } from "@hotwired/stimulus"
import L from "leaflet"

// Corregge le icone Leaflet rotte quando il bundler cambia i percorsi degli asset
import iconRetinaUrl from "leaflet/dist/images/marker-icon-2x.png"
import iconUrl from "leaflet/dist/images/marker-icon.png"
import shadowUrl from "leaflet/dist/images/marker-shadow.png"

delete L.Icon.Default.prototype._getIconUrl
L.Icon.Default.mergeOptions({ iconRetinaUrl, iconUrl, shadowUrl })

const ITALY_CENTER = [41.9, 12.5]
const ITALY_ZOOM = 5

export default class extends Controller {
  static values = {
    query: { type: String, default: "" },
    zoom: { type: Number, default: 8 }
  }

  async connect() {
    // Aspetta che il browser abbia calcolato le dimensioni del container
    // (se il container ha size=0 al momento di connect(), le tile vengono piazzate male)
    await new Promise(resolve => requestAnimationFrame(resolve))

    this.#initMap()

    if (this.queryValue) {
      await this.#geocodeAndFit(this.queryValue)
    } else {
      this.map.setView(ITALY_CENTER, ITALY_ZOOM)
    }

    // Forza il ricalcolo delle dimensioni dopo il rendering
    this.map.invalidateSize()
  }

  disconnect() {
    if (this.map) {
      this.map.remove()
      this.map = null
    }
  }

  #initMap() {
    this.map = L.map(this.element)
    L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 19,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a>'
    }).addTo(this.map)
  }

  async #geocodeAndFit(query) {
    try {
      const url = `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(query)}&format=json&limit=1&accept-language=it`
      const res = await fetch(url, { headers: { "User-Agent": "Airesis/6.0 (airesis.eu)" } })
      const data = await res.json()

      if (!this.map) return // disconnected mentre aspettava

      if (data.length > 0) {
        const { lat, lon, boundingbox } = data[0]
        if (boundingbox) {
          // [minLat, maxLat, minLon, maxLon]
          this.map.fitBounds([
            [parseFloat(boundingbox[0]), parseFloat(boundingbox[2])],
            [parseFloat(boundingbox[1]), parseFloat(boundingbox[3])]
          ])
        } else {
          this.map.setView([parseFloat(lat), parseFloat(lon)], this.zoomValue)
        }
      } else {
        this.map.setView(ITALY_CENTER, ITALY_ZOOM)
      }
      this.map.invalidateSize()
    } catch {
      if (this.map) {
        this.map.setView(ITALY_CENTER, ITALY_ZOOM)
        this.map.invalidateSize()
      }
    }
  }
}
