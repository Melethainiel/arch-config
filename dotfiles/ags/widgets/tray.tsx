import { createBinding, For } from "ags"
import TrayService from "gi://AstalTray"

function TrayItem({ item }: { item: AstalTray.TrayItem }) {
  return (
    <menubutton
      class="tray-item"
      tooltipMarkup={createBinding(item, "tooltipMarkup")}
      $={(button) => button.insert_action_group("dbusmenu", item.actionGroup)}
      menuModel={createBinding(item, "menuModel")}
    >
      <image gicon={createBinding(item, "gicon")} pixelSize={16} />
    </menubutton>
  )
}

export function Tray() {
  const tray = TrayService.get_default()
  const items = createBinding(tray, "items")

  return (
    <box class="bubble tray" visible={items.as((items) => items.length > 0)} spacing={4}>
      <For each={items}>{(item) => <TrayItem item={item} />}</For>
    </box>
  )
}
