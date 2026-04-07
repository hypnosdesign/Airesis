import { Controller } from "@hotwired/stimulus"
import ApexCharts from "apexcharts"

// Wrapper Stimulus per ApexCharts.
// Uso: <div data-controller="chart" data-chart-type-value="donut" data-chart-data-value='<%= {...}.to_json %>'>
export default class extends Controller {
  static values = { data: Object, type: String }

  connect() {
    this.chart = new ApexCharts(this.element, this.buildOptions())
    this.chart.render()

    // Aggiorna il tema quando il toggle dark/light cambia
    this._themeObserver = new MutationObserver(() => this.updateTheme())
    this._themeObserver.observe(document.documentElement, { attributes: true, attributeFilter: ["data-theme"] })
  }

  disconnect() {
    this._themeObserver?.disconnect()
    this.chart?.destroy()
  }

  buildOptions() {
    const isDark = document.documentElement.getAttribute("data-theme") === "night"
    return {
      chart: {
        type: this.typeValue || "donut",
        height: 220,
        background: "transparent",
        toolbar: { show: false },
        animations: { enabled: true, speed: 400 }
      },
      theme: { mode: isDark ? "dark" : "light" },
      legend: { position: "bottom", fontSize: "12px" },
      dataLabels: { enabled: false },
      stroke: { width: 0 },
      ...this.dataValue
    }
  }

  updateTheme() {
    const isDark = document.documentElement.getAttribute("data-theme") === "night"
    this.chart?.updateOptions({ theme: { mode: isDark ? "dark" : "light" } })
  }
}
