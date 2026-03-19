import "@hotwired/turbo-rails"
import "bootstrap"
import { Application } from "@hotwired/stimulus"
import SearchController from "controllers/search_controller"

const application = Application.start()
application.register("search", SearchController)

document.addEventListener("turbo:load", () => {
  document.querySelectorAll("[data-bs-toggle='tooltip']").forEach((el) => {
    new bootstrap.Tooltip(el)
  })
})
