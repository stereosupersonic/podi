// Entry point for the build script in your package.json
import "./src/jquery.js"
import "@hotwired/turbo-rails"

import * as bootstrap from "bootstrap"


window.addEventListener("load", function() {
  $('[data-toggle="tooltip"]').tooltip({
    trigger: 'hover'
  });
});
