import app from "ags/gtk4/app"
import css from "./style.css"
import { Bar } from "./widgets/bar"

app.start({
  css,
  instanceName: "arch-shell",
  main() {
    app.get_monitors().forEach((_, monitor) => Bar(monitor))
  },
})
