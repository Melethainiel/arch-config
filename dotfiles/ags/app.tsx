import app from "ags/gtk4/app"
import { createRoot } from "ags"
import css from "./style.css"
import theme from "./theme.css"
import { Bar } from "./widgets/bar"

declare const ARCH_SHELL_TEST: boolean | undefined

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
  css: `${theme}\n${css}`,
  instanceName: typeof ARCH_SHELL_TEST === "boolean" && ARCH_SHELL_TEST ? "arch-shell-theme-test" : "arch-shell",
  main() {
    syncBars()
    app.connect("notify::monitors", syncBars)
  },
})
