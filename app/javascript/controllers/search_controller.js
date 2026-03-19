import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "form"]

  toggle() {
    this.inputTarget.classList.toggle("d-none")
    if (!this.inputTarget.classList.contains("d-none")) {
      this.inputTarget.querySelector("input").focus()
    }
  }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.formTarget.requestSubmit()
    }, 300)
  }

  close(event) {
    if (!this.element.contains(event.target)) {
      this.inputTarget.classList.add("d-none")
    }
  }
}
