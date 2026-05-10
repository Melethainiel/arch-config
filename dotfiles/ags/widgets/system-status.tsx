import { createPoll } from "ags/time"

export function SystemStatus() {
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
