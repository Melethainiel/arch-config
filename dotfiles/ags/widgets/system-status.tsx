import { createPoll } from "ags/time"
import { run } from "../lib/run"

const batteryCommand = `
device=$(upower -e 2>/dev/null | grep '/battery_BAT' | head -n1)
[ -n "$device" ] || exit 0

info=$(upower -i "$device" 2>/dev/null)
percentage=$(printf '%s\n' "$info" | sed -n 's/.*percentage:[[:space:]]*//p' | head -n1)
state=$(printf '%s\n' "$info" | sed -n 's/.*state:[[:space:]]*//p' | head -n1)
time=$(printf '%s\n' "$info" | sed -En 's/.*time to (empty|full):[[:space:]]*//p' | head -n1)
native_path=$(printf '%s\n' "$info" | sed -n 's/.*native-path:[[:space:]]*//p' | head -n1)
bat=/sys/class/power_supply/$native_path
energy_now=$(cat "$bat/energy_now" 2>/dev/null || true)
energy_full=$(cat "$bat/energy_full" 2>/dev/null || true)
power_now=$(cat "$bat/power_now" 2>/dev/null || true)
runtime_dir=$XDG_RUNTIME_DIR
[ -n "$runtime_dir" ] || runtime_dir=/tmp
state_file=$runtime_dir/arch-config-battery-energy

if [ -n "$energy_now" ] && [ -f "$state_file" ]; then
  previous_energy=$(cat "$state_file" 2>/dev/null || true)

  if [ -n "$previous_energy" ] && [ "$energy_now" -lt "$previous_energy" ] 2>/dev/null; then
    state=discharging
    time=
  elif [ -n "$previous_energy" ] && [ "$energy_now" -gt "$previous_energy" ] 2>/dev/null; then
    state=charging
    time=
  fi
fi

[ -n "$energy_now" ] && printf '%s' "$energy_now" > "$state_file"

format_seconds() {
  hours=$(( $1 / 3600 ))
  minutes=$(( ($1 % 3600) / 60 ))

  if [ "$hours" -gt 0 ]; then
    printf '%dh%02d' "$hours" "$minutes"
  else
    printf '%dmin' "$minutes"
  fi
}

format_upower_time() {
  value=$1
  unit=$2

  case "$unit" in
    hour|hours)
      awk -v value="$value" 'BEGIN { hours = int(value); minutes = int((value - hours) * 60); printf "%dh%02d", hours, minutes }'
      ;;
    minute|minutes)
      awk -v value="$value" 'BEGIN { printf "%dmin", int(value) }'
      ;;
    *)
      printf '%s %s' "$value" "$unit"
      ;;
  esac
}

[ -n "$time" ] && time=$(format_upower_time $time)

if [ -z "$time" ]; then
  if [ -n "$power_now" ] && [ "$power_now" -gt 0 ] 2>/dev/null; then
    case "$state" in
      charging|pending-charge)
        [ -n "$energy_full" ] && [ -n "$energy_now" ] && seconds=$(( (energy_full - energy_now) * 3600 / power_now ))
        ;;
      discharging|pending-discharge)
        [ -n "$energy_now" ] && seconds=$(( energy_now * 3600 / power_now ))
        ;;
    esac

    [ -n "$seconds" ] && [ "$seconds" -gt 0 ] 2>/dev/null && time=$(format_seconds "$seconds")
  fi
fi

case "$state" in
  charging) icon='' ;;
  discharging) icon='' ;;
  fully-charged) icon='' ;;
  pending-charge) icon='' ;;
  pending-discharge) icon='' ;;
  *) icon='' ;;
esac

if [ -n "$time" ]; then
  printf '%s %s %s' "$icon" "$percentage" "$time"
else
  printf '%s %s' "$icon" "$percentage"
fi
`

const networkCommand = `
strip_ansi() {
  sed 's/\x1b\[[0-9;]*m//g'
}

default_iface=$(ip route show default 2>/dev/null | awk '{ for (i = 1; i <= NF; i++) if ($i == "dev") { print $(i + 1); exit } }')

if [ -n "$default_iface" ] && [ ! -d "/sys/class/net/$default_iface/wireless" ]; then
  printf 'ETH'
  exit 0
fi

iface=$default_iface
[ -n "$iface" ] || iface=$(iwctl station list 2>/dev/null | strip_ansi | awk '$2 == "connected" { print $1; exit }')
[ -n "$iface" ] || { printf 'OFF'; exit 0; }

network=$(iwctl station "$iface" show 2>/dev/null | strip_ansi | sed -n 's/.*Connected network[[:space:]]*//p' | head -n1)
[ -n "$network" ] && printf '%s' "$network" || printf 'OFF'
`

export function SystemStatus() {
  const notifications = createPoll("0", 1000, [
    "bash",
    "-c",
    "command -v swaync-client >/dev/null 2>&1 && swaync-client -c 2>/dev/null || printf 0",
  ], (out) => out.trim() || "0")

  const volume = createPoll("", 1000, [
    "bash",
    "-c",
    "pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -o '[0-9][0-9]*%' | head -n1 || true",
  ], (out) => out.trim())

  const network = createPoll("", 5000, [
    "bash",
    "-c",
    networkCommand,
  ], (out) => {
    const val = out.trim()
    if (val === "ETH") return "󰈀 ethernet"
    if (val && val !== "OFF") return ` ${val}`
    return " off"
  })

  const battery = createPoll("", 5000, [
    "bash",
    "-c",
    batteryCommand,
  ], (out) => out.trim())

  return (
    <box class="status" spacing={8}>
      <button class="bubble volume" visible={volume((value) => value.length > 0)} onClicked={() => run(["ghostty", "--class=com.mitchellh.ghostty.wiremix", "-e", "wiremix"])}>
        <label label={volume((value) => ` ${value}`)} />
      </button>
      <button class="bubble network" onClicked={() => run(["ghostty", "--class=com.mitchellh.ghostty.impala", "-e", "impala"])}>
        <label label={network((value) => value)} />
      </button>
      <label class="bubble battery" visible={battery((value) => value.length > 0)} xalign={0} label={battery((value) => value)} />
      <button class="bubble notifications" onClicked={() => run(["swaync-client", "-t", "-sw"])}>
        <label label={notifications((count) => Number(count) > 0 ? "󱅫" : "")} />
      </button>
    </box>
  )
}
