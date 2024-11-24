// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

import Alpine from "alpinejs";

window.Alpine = Alpine;
Alpine.start();

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
    dom: {
    onBeforeElUpdated (from, to) {
      if (from._x_dataStack) {
        window.Alpine.clone(from, to)
      }
    },
  },

  params: {_csrf_token: csrfToken}
})

function applyColorSchemePreference() {
    const darkExpected = window.matchMedia('(prefers-color-scheme: dark)').matches;
    if (darkExpected) {
        document.documentElement.classList.add('dark');
        document.documentElement.style.setProperty('color-scheme', 'dark');
    }
    else {
        document.documentElement.classList.remove('dark');
        document.documentElement.style.setProperty('color-scheme', 'light');
    }
}

// set listener to update color scheme preference on change
window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', event => {
    const newColorScheme = event.matches ? "dark" : "light";
    applyColorSchemePreference();
});

// check color scheme preference on page load
applyColorSchemePreference();


// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())
window.addEventListener("phx:focus", (e) => { 
  el = document.getElementById(e.detail.id)
  setTimeout(() => el.focus(), 0)
});

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

