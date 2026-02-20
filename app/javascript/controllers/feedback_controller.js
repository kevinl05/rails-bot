import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, current: String }
  static targets = ["up", "down"]

  thumbsUp() {
    const newValue = this.currentValue === "thumbs_up" ? "" : "thumbs_up"
    this.sendFeedback(newValue)
  }

  thumbsDown() {
    const newValue = this.currentValue === "thumbs_down" ? "" : "thumbs_down"
    this.sendFeedback(newValue)
  }

  sendFeedback(feedback) {
    this.currentValue = feedback
    this.updateStyles()

    const token = document.querySelector('meta[name="csrf-token"]')?.content

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": token
      },
      body: JSON.stringify({ feedback: feedback || null })
    }).catch((error) => {
      console.error("Feedback error:", error)
    })
  }

  updateStyles() {
    this.upTarget.className = "p-1 rounded transition-colors text-gray-600 hover:text-green-400"
    this.downTarget.className = "p-1 rounded transition-colors text-gray-600 hover:text-red-400"

    if (this.currentValue === "thumbs_up") {
      this.upTarget.className = "p-1 rounded transition-colors text-green-400"
    } else if (this.currentValue === "thumbs_down") {
      this.downTarget.className = "p-1 rounded transition-colors text-red-400"
    }
  }
}
