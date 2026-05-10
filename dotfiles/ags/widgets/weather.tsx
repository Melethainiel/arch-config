import { createPoll } from "ags/time"

export function Weather() {
  const weather = createPoll("meteo", 900000, [
    "bash",
    "-c",
    "curl -fsS 'https://wttr.in/Saint-Chamond?format=%c+%t' 2>/dev/null || true",
  ], (out) => out.trim() || "meteo")

  return <label class="bubble weather" label={weather} />
}
