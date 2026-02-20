import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "submit"]

  submitMessage(event) {
    event.preventDefault()

    const content = this.inputTarget.value.trim()
    if (!content) return

    this.inputTarget.value = ""
    this.inputTarget.style.height = "auto"
    this.submitTarget.disabled = true

    // Append user message immediately
    const messagesDiv = document.getElementById("messages")
    const userBubble = document.createElement("div")
    userBubble.className = "flex justify-end"
    userBubble.innerHTML = `
      <div class="max-w-[80%] bg-red-600/20 border-red-600/30 rounded-2xl px-5 py-3 border">
        <div class="prose prose-invert prose-sm max-w-none text-gray-200 whitespace-pre-wrap">${this.escapeHtml(content)}</div>
      </div>
    `
    messagesDiv.appendChild(userBubble)

    // Show thinking indicator
    const thinkingBubble = document.createElement("div")
    thinkingBubble.id = "thinking-indicator"
    thinkingBubble.className = "flex justify-start"
    thinkingBubble.innerHTML = `
      <div class="max-w-[80%] bg-gray-800 border-gray-700 rounded-2xl px-5 py-3 border">
        <div class="text-xs text-red-400 font-semibold mb-1">Rails</div>
        <div class="flex items-center gap-1 text-gray-400">
          <span class="animate-pulse">●</span>
          <span class="animate-pulse [animation-delay:150ms]">●</span>
          <span class="animate-pulse [animation-delay:300ms]">●</span>
        </div>
      </div>
    `
    messagesDiv.appendChild(thinkingBubble)
    this.scrollToBottom()

    // Send the message
    const form = this.element
    const formData = new FormData()
    formData.append("message[content]", content)

    fetch(form.action, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "text/vnd.turbo-stream.html"
      },
      body: formData
    }).then(() => {
      // Remove thinking indicator (the broadcast will add the real message)
      const indicator = document.getElementById("thinking-indicator")
      if (indicator) indicator.remove()
      this.submitTarget.disabled = false
      this.inputTarget.focus()
    }).catch((error) => {
      const indicator = document.getElementById("thinking-indicator")
      if (indicator) {
        indicator.innerHTML = `
          <div class="max-w-[80%] bg-red-900/30 border-red-800 rounded-2xl px-5 py-3 border">
            <div class="text-sm text-red-400">Something went wrong. Try again.</div>
          </div>
        `
      }
      this.submitTarget.disabled = false
    })
  }

  handleKeydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.submitMessage(event)
    }
  }

  autoResize() {
    const textarea = this.inputTarget
    textarea.style.height = "auto"
    textarea.style.height = Math.min(textarea.scrollHeight, 200) + "px"
  }

  scrollToBottom() {
    const container = document.getElementById("messages-container")
    if (container) {
      container.scrollTop = container.scrollHeight
    }
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
