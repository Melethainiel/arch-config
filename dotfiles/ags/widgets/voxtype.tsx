import { createPoll } from "ags/time"
import { run } from "../lib/run"

type VoxtypeStatus = {
  class: string
  tooltip: string
  model?: string
}

const statusCommand = `
if ! command -v voxtype >/dev/null 2>&1; then
  printf '{"class":"missing","tooltip":"Voxtype is not installed"}'
  exit 0
fi

status=$(voxtype status --format json --extended 2>/dev/null) || {
  printf '{"class":"stopped","tooltip":"Voxtype daemon is stopped"}'
  exit 0
}

model=$(printf '%s' "$status" | sed -n 's/.*"model": "\\([^\"]*\\)".*/\\1/p')

if [ -n "$model" ] && [ ! -f "$HOME/.local/share/voxtype/models/ggml-$model.bin" ]; then
  printf '{"class":"setup","tooltip":"Voxtype model is not downloaded","model":"%s"}' "$model"
  exit 0
fi

printf '%s' "$status"
`

function statusLabel(status: VoxtypeStatus) {
  if (status.class === "missing") return " missing"
  if (status.class === "setup") return " setup"
  if (status.class === "stopped") return " off"
  if (status.class.includes("record")) return " rec"
  if (status.class.includes("transcrib")) return " txt"
  return ""
}

function statusTooltip(status: VoxtypeStatus) {
  const details = status.model ? `\nModel: ${status.model}` : ""

  return `${status.tooltip || "Voxtype ready"}${details}\nClick: setup`
}

export function Voxtype() {
  const status = createPoll<VoxtypeStatus>({ class: "stopped", tooltip: "Voxtype daemon is stopped" }, 1000, [
    "bash",
    "-c",
    statusCommand,
  ], (out) => {
    try {
      const parsed = JSON.parse(out.trim() || "{}") as VoxtypeStatus

      return {
        class: parsed.class || "idle",
        tooltip: parsed.tooltip || "Voxtype ready",
        model: parsed.model,
      }
    } catch {
      return { class: "unknown", tooltip: "Voxtype status unavailable" }
    }
  })

  return (
    <button
      class={status((value) => `bubble voxtype ${value.class}`)}
      tooltipText={status(statusTooltip)}
      onClicked={() => run(["ghostty", "--class=com.mitchellh.ghostty.voxtype", "-e", "bash", "-lc", "arch-setup-voxtype; read -n1 -r -p 'Press any key to close'"])}
    >
      <label label={status(statusLabel)} />
    </button>
  )
}
