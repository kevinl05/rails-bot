import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["icon", "check", "source"]

  copy() {
    const content = this.sourceTarget.value
    const textarea = document.createElement("textarea")
    textarea.value = content
    textarea.style.position = "fixed"
    textarea.style.opacity = "0"
    document.body.appendChild(textarea)
    textarea.select()
    document.execCommand("copy")
    document.body.removeChild(textarea)

    this.iconTarget.classList.add("hidden")
    this.checkTarget.classList.remove("hidden")

    setTimeout(() => {
      this.checkTarget.classList.add("hidden")
      this.iconTarget.classList.remove("hidden")
    }, 1500)
  }
}
