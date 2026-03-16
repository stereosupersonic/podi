import "@hotwired/turbo-rails"
import * as bootstrap from "bootstrap"

document.addEventListener("turbo:load", () => {
  document.querySelectorAll("[data-bs-toggle='tooltip']").forEach((el) => {
    new bootstrap.Tooltip(el)
  })
})
