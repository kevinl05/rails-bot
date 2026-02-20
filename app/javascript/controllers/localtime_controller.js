import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { utc: String }

  connect() {
    const date = new Date(this.utcValue)
    this.element.textContent = date.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" })
  }
}
