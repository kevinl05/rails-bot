import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["icon", "check", "source"]

  copy() {
    const content = this.sourceTarget.content.textContent || this.sourceTarget.textContent
    navigator.clipboard.writeText(content).then(() => {
      this.iconTarget.classList.add("hidden")
      this.checkTarget.classList.remove("hidden")

      setTimeout(() => {
        this.checkTarget.classList.add("hidden")
        this.iconTarget.classList.remove("hidden")
      }, 1500)
    })
  }
}
