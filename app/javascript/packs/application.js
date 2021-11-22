
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
const images = require.context('../images', true)
const imagePath = (name) => images(name, true)
require("@rails/ujs").start()
require("turbolinks").start()

import 'bootstrap/dist/js/bootstrap'
import "@fortawesome/fontawesome-free/css/all.css";
// custom css
require("css/application.scss")


document.addEventListener("turbolinks:load", () => {

});
