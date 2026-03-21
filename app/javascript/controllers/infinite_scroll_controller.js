import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sentinel"]

  sentinelTargetConnected(sentinel) {
    this.observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          this.loadMore(entry.target)
        }
      })
    })
    this.observer.observe(sentinel)
  }

  sentinelTargetDisconnected(sentinel) {
    if (this.observer) {
      this.observer.unobserve(sentinel)
    }
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  async loadMore(sentinel) {
    const url = sentinel.dataset.url
    if (!url) return

    this.observer.unobserve(sentinel)

    const response = await fetch(url, {
      headers: {
        "X-Requested-With": "XMLHttpRequest",
        "Accept": "text/html"
      }
    })

    if (response.ok) {
      const html = await response.text()
      sentinel.outerHTML = html
    }
  }
}
