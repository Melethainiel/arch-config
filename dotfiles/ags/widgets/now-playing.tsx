import { createPoll } from "ags/time"
import { run } from "../lib/run"

export function NowPlaying() {
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
