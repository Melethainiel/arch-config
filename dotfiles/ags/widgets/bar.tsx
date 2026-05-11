import app from "ags/gtk4/app"
import { Astal } from "ags/gtk4"
import { createPoll } from "ags/time"
import { NowPlaying } from "./now-playing"
import { SystemStatus } from "./system-status"
import { Voxtype } from "./voxtype"
import { Weather } from "./weather"
import { Workspaces } from "./workspaces"

export function Bar(monitor = 0) {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor
  const clock = createPoll("", 1000, () => {
    return new Date().toLocaleString("fr-FR", {
      weekday: "short",
      hour: "2-digit",
      minute: "2-digit",
    })
  })

  return (
    <window visible name={`bar-${monitor}`} class="bar-window" monitor={monitor} anchor={TOP | LEFT | RIGHT} exclusivity={Astal.Exclusivity.EXCLUSIVE} application={app}>
      <centerbox class="bar">
        <box $type="start" class="left" spacing={8}>
          <box class="bubble brand">
            <label class="brand-icon" label="" />
          </box>
          <Voxtype />
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
