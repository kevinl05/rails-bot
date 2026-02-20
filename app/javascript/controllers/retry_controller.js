import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }
  static targets = ["button"]

  retry() {
    const messageDiv = this.element.closest("[id^='message_']")
    const bubble = messageDiv.querySelector(".markdown-body")
    const originalContent = bubble.innerHTML

    // Show thinking indicator in the bubble
    bubble.innerHTML = `
      <div class="flex items-center gap-1 text-gray-400">
        <span class="animate-pulse">●</span>
        <span class="animate-pulse" style="animation-delay:150ms">●</span>
        <span class="animate-pulse" style="animation-delay:300ms">●</span>
      </div>
    `
    this.buttonTarget.disabled = true

    const token = document.querySelector('meta[name="csrf-token"]')?.content

    fetch(this.urlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": token,
        "Accept": "text/vnd.turbo-stream.html"
      }
    }).then(response => {
      if (!response.ok) {
        bubble.innerHTML = originalContent
        this.buttonTarget.disabled = false
      }
    }).catch(() => {
      bubble.innerHTML = originalContent
      this.buttonTarget.disabled = false
    })
  }
}
