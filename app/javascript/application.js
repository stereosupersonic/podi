// Entry point for the build script in your package.json

import "@hotwired/turbo-rails"

import * as bootstrap from "bootstrap"

import "./src/jquery.js"

$(document).on("turbo:load", function () {
  $("[data-toggle='tooltip']").tooltip();
});
