import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["participants", "participantsOutput", "voteParticipants", "voteParticipantsOutput"]
  static values = { participantsTotal: Number, voteParticipantsTotal: Number }

  connect() {
    this.updateParticipants()
    this.updateVoteParticipants()
  }

  updateParticipants() {
    if (!this.hasParticipantsTarget || !this.hasParticipantsOutputTarget) return
    this.participantsOutputTarget.textContent = this.calculate(this.participantsTarget.value, this.participantsTotalValue)
  }

  updateVoteParticipants() {
    if (!this.hasVoteParticipantsTarget || !this.hasVoteParticipantsOutputTarget) return
    this.voteParticipantsOutputTarget.textContent = this.calculate(this.voteParticipantsTarget.value, this.voteParticipantsTotalValue)
  }

  calculate(percentage, total) {
    if (total <= 0) return 0
    return Math.min(Math.floor(Number(percentage || 0) * 0.01 * total) + 1, total)
  }
}
