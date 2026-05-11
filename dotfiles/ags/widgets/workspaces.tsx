import type { Accessor } from "ags"
import { createPoll } from "ags/time"
import { run } from "../lib/run"

const workspaces = [
  { id: 1, label: "󰖟 1" },
  { id: 2, label: "󰊴 2" },
  { id: 3, label: "󰆍 3" },
  { id: 4, label: "4" },
  { id: 5, label: "5" },
  { id: 6, label: "6" },
]

function WorkspaceButton({ id, label, active }: { id: number; label: string; active: Accessor<string> }) {
  return (
    <button
      class="workspace-button"
      onClicked={() => run(["hyprctl", "dispatch", "workspace", id.toString()])}
    >
      <label class={active((current) => current === id.toString() ? "workspace active" : "workspace")} label={label} />
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
      {workspaces.map((workspace) => <WorkspaceButton {...workspace} active={active} />)}
    </box>
  )
}
