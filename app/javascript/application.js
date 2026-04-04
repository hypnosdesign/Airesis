// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

// Utility: swap link text with data-other attribute (used by like/unlike buttons)
window.switchText = function(el) {
  var other = el.dataset ? el.dataset.other : el.getAttribute('data-other');
  if (other) {
    var current = el.textContent;
    el.textContent = other;
    el.dataset.other = current;
  }
}
