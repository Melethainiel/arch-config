import app from "ags/gtk4/app"
import { createRoot } from "ags"
import css from "./style.css"
import { Bar } from "./widgets/bar"

let barDisposers: Array<() => void> = []

function syncBars() {
  barDisposers.forEach((dispose) => dispose())
  barDisposers = []

  app.windows
    .filter((window) => window.name.startsWith("bar-"))
    .forEach((window) => window.destroy())

  app.get_monitors().forEach((_, monitor) => {
    createRoot((dispose) => {
      const window = Bar(monitor)

      barDisposers.push(() => {
        window.destroy()
        dispose()
      })

      return window
    })
  })
}

app.start({
  css,
  instanceName: "arch-shell",
  main() {
    syncBars()
    app.connect("notify::monitors", syncBars)
  },
})
