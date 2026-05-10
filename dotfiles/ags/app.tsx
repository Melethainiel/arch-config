import app from "ags/gtk4/app"
import type { Accessor } from "ags"
import { Astal } from "ags/gtk4"
import { createPoll } from "ags/time"
import { execAsync } from "ags/process"
import css from "./style.css"

const workspaces = [1, 2, 3, 4, 5, 6]

function run(command: string[]) {
  execAsync(command).catch((error) => console.error(error))
}

function WorkspaceButton({ id, active }: { id: number; active: Accessor<string> }) {
  return (
    <button
      class="workspace-button"
      onClicked={() => run(["hyprctl", "dispatch", "workspace", id.toString()])}
    >
      <label class={active((current) => current === id.toString() ? "workspace active" : "workspace")} label={id.toString()} />
    </button>
  )
}

function Workspaces() {
  const active = createPoll("1", 300, [
    "bash",
    "-c",
    "hyprctl activeworkspace | sed -n 's/^workspace ID \\([0-9]*\\).*/\\1/p'",
  ])

  return (
    <box class="workspaces" spacing={6}>
      {workspaces.map((id) => <WorkspaceButton id={id} active={active} />)}
    </box>
  )
}

function NowPlaying() {
  const status = createPoll("Stopped", 1000, [
    "bash",
    "-c",
    "playerctl status 2>/dev/null || true",
  ], (out) => out.trim() || "Stopped")

  const title = createPoll("rien en cours              ", 500, [
    "bash",
    "-c",
    "text=$(playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null || true); text=${text:-rien en cours}; width=28; padded=\"$text                            \"; len=${#padded}; pos=0; [ ${#text} -gt $width ] && pos=$(( ($(date +%s%3N) / 500) % len )); printf '%s' \"$padded$padded\" | cut -c $((pos + 1))-$((pos + width))",
  ], (out) => out || "rien en cours              ")

  return (
    <button class="bubble media" visible={status((value) => value !== "Stopped")} onClicked={() => run(["playerctl", "play-pause"])}>
      <box class="media-content" spacing={8}>
        <label label={status((value) => value === "Playing" ? "⏸" : "▶")} />
        <label class="media-title" label={title} />
      </box>
    </button>
  )
}

function Weather() {
  const weather = createPoll("meteo", 900000, [
    "bash",
    "-c",
    "curl -fsS 'https://wttr.in/Saint-Chamond?format=%c+%t' 2>/dev/null || true",
  ], (out) => out.trim() || "meteo")

  return <label class="bubble weather" label={weather} />
}

function SystemStatus() {
  const volume = createPoll("", 1000, [
    "bash",
    "-c",
    "pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -o '[0-9][0-9]*%' | head -n1 || true",
  ], (out) => out.trim())

  const network = createPoll("wifi", 5000, [
    "bash",
    "-c",
    "iwctl station wlan0 show 2>/dev/null | sed -n 's/.*Connected network[[:space:]]*//p' | head -n1 || true",
  ], (out) => out.trim() || "wifi")

  const battery = createPoll("", 30000, [
    "bash",
    "-c",
    "for b in /sys/class/power_supply/BAT*/capacity; do [ -r \"$b\" ] && printf '%s%%' \"$(cat \"$b\")\" && exit 0; done; true",
  ], (out) => out.trim())

  return (
    <box class="status" spacing={8}>
      <label class="bubble volume" visible={volume((value) => value.length > 0)} label={volume((value) => ` ${value}`)} />
      <label class="bubble network" label={network((value) => `󰖩 ${value}`)} />
      <label class="bubble battery" visible={battery((value) => value.length > 0)} label={battery((value) => `󰁹 ${value}`)} />
      <label class="bubble notifications" label="" />
    </box>
  )
}

function Bar(monitor = 0) {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor
  const clock = createPoll("", 1000, () => {
    return new Date().toLocaleString("fr-FR", {
      weekday: "short",
      hour: "2-digit",
      minute: "2-digit",
    })
  })

  return (
    <window visible name="bar" class="bar-window" monitor={monitor} anchor={TOP | LEFT | RIGHT} exclusivity={Astal.Exclusivity.EXCLUSIVE} application={app}>
      <centerbox class="bar">
        <box $type="start" class="left" spacing={8}>
          <box class="bubble brand">
            <label class="brand-icon" label="" />
          </box>
          <NowPlaying />
          <Weather />
        </box>

        <box $type="center" class="center" spacing={8}>
          <label class="bubble clock" label={clock} />
          <box class="bubble workspace-bubble">
            <Workspaces />
          </box>
        </box>

        <box $type="end" class="right" spacing={8}>
          <SystemStatus />
        </box>
      </centerbox>
    </window>
  )
}

app.start({
  css,
  instanceName: "arch-shell",
  main() {
    app.get_monitors().forEach((_, monitor) => Bar(monitor))
  },
})
