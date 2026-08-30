import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["rank", "votes"]
  static values = { errorMessage: String }

  connect() {
    this.update()
  }

  update() {
    this.rankTargets.forEach((select) => select.setCustomValidity(""))
    const ordered = [...this.rankTargets].sort((left, right) => Number(left.value) - Number(right.value))
    this.votesTarget.value = ordered.map((select) => select.dataset.solutionId).join(",")
  }

  validate(event) {
    this.update()
    const values = this.rankTargets.map((select) => select.value)
    const duplicate = this.rankTargets.find((select, index) => values.indexOf(select.value) !== index)
    if (!duplicate) return

    event.preventDefault()
    duplicate.setCustomValidity(this.errorMessageValue)
    duplicate.reportValidity()
  }
}
