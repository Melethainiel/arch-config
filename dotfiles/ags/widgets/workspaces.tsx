import type { Accessor } from "ags"
import { createPoll } from "ags/time"
import { run } from "../lib/run"

const workspaces = [1, 2, 3, 4, 5, 6]

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

export function Workspaces() {
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
