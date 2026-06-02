import QtQuick
import QtQuick.Layouts
import Quickshell
import "components"

ShellRoot {
  id: root

  property var workspaces: [
    { "id": 1, "label": "󰖟 1" },
    { "id": 2, "label": "󰊴 2" },
    { "id": 3, "label": "󰆍 3" },
    { "id": 4, "label": "4" },
    { "id": 5, "label": "5" },
    { "id": 6, "label": "6" }
  ]
  property string fontFamily: "JetBrainsMono Nerd Font"

  function parseJson(text, fallback) {
    try {
      return JSON.parse(text || fallback)
    } catch (error) {
      return JSON.parse(fallback)
    }
  }

  Theme { id: theme }

  CommandPoller {
    id: activeWorkspace
    interval: 300
    command: ["sh", "-c", "hyprctl activeworkspace | sed -n 's/^workspace ID \\([0-9]*\\).*/\\1/p'"]
  }

  CommandPoller {
    id: mediaStatus
    interval: 1000
    command: ["sh", "-c", "playerctl status 2>/dev/null || true"]
    text: "Stopped"
  }

  CommandPoller {
    id: mediaTitle
    interval: 500
    command: ["sh", "-c", "title=$(playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null || printf 'rien en cours'); width=28; len=${#title}; if [ \"$len\" -le \"$width\" ]; then printf '%s' \"$title\"; else pad='   '; loop=\"$title$pad\"; offset=$((($(date +%s%3N) / 450) % (${#loop}))); printf '%s%s' \"${loop:$offset}\" \"${loop:0:$offset}\" | cut -c1-$width; fi"]
  }

  CommandPoller {
    id: weather
    interval: 900000
    command: ["sh", "-c", "curl -fsS 'https://wttr.in/Saint-Chamond?format=%c+%t' 2>/dev/null || printf 'meteo'"]
  }

  CommandPoller {
    id: voxtype
    interval: 1000
    command: ["sh", "-c", "if ! command -v voxtype >/dev/null 2>&1; then printf '{\"class\":\"missing\",\"tooltip\":\"Voxtype is not installed\"}'; exit 0; fi; status=$(voxtype status --format json --extended 2>/dev/null || printf '{\"class\":\"stopped\",\"tooltip\":\"Voxtype service stopped\"}'); model=$(printf '%s' \"$status\" | sed -n 's/.*\"model\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p'); if [ -n \"$model\" ] && [ ! -f \"$HOME/.local/share/voxtype/models/ggml-$model.bin\" ]; then printf '{\"class\":\"setup\",\"tooltip\":\"Missing speech model\",\"model\":\"%s\"}' \"$model\"; else printf '%s' \"$status\"; fi"]
  }

  CommandPoller {
    id: volume
    interval: 1000
    command: ["sh", "-c", "pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -o '[0-9][0-9]*%' | head -n1"]
  }

  CommandPoller {
    id: network
    interval: 5000
    command: ["sh", "-c", "iface=$(ip route show default 2>/dev/null | awk 'NR==1 {print $5}'); [ -z \"$iface\" ] && { printf OFF; exit 0; }; [ ! -d \"/sys/class/net/$iface/wireless\" ] && { printf ETH; exit 0; }; iwctl station \"$iface\" show 2>/dev/null | sed -n 's/^[[:space:]]*Connected network[[:space:]]*//p' | head -n1 | grep -q . && iwctl station \"$iface\" show 2>/dev/null | sed -n 's/^[[:space:]]*Connected network[[:space:]]*//p' | head -n1 || printf OFF"]
  }

  CommandPoller {
    id: bluetooth
    interval: 5000
    command: ["sh", "-c", "if ! command -v bluetoothctl >/dev/null 2>&1; then printf 'missing|off'; exit 0; fi; if ! bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then printf 'off|off'; exit 0; fi; labels=$(bluetoothctl devices Connected 2>/dev/null | while IFS= read -r line; do rest=${line#Device }; mac=${rest%% *}; name=${rest#* }; [ -n \"$mac\" ] && [ \"$mac\" != \"$rest\" ] || continue; info=$(bluetoothctl info \"$mac\" 2>/dev/null); pct=$(printf '%s' \"$info\" | awk -F'[()]' '/Battery Percentage/ {print $2; exit}'); if [ -n \"$pct\" ]; then printf '%s %s%%\\n' \"$name\" \"$pct\"; else printf '%s\\n' \"$name\"; fi; done | paste -sd '/' -); if [ -n \"$labels\" ]; then printf 'connected|%s' \"$labels\"; else printf 'on|on'; fi"]
  }

  CommandPoller {
    id: battery
    interval: 5000
    command: ["sh", "-c", "for dev in $(upower -e 2>/dev/null | grep battery); do info=$(upower -i \"$dev\"); printf '%s' \"$info\" | grep -q '^[[:space:]]*power supply:[[:space:]]*yes' || continue; pct=$(printf '%s' \"$info\" | sed -n 's/^[[:space:]]*percentage:[[:space:]]*//p' | head -n1); state=$(printf '%s' \"$info\" | sed -n 's/^[[:space:]]*state:[[:space:]]*//p' | head -n1); [ -z \"$pct\" ] && continue; case \"$state\" in charging) icon= ;; fully-charged) icon= ;; discharging) icon= ;; *) icon= ;; esac; printf '%s|%s' \"$icon\" \"$pct\"; break; done"]
  }

  CommandPoller {
    id: notifications
    interval: 1000
    command: ["sh", "-c", "command -v swaync-client >/dev/null 2>&1 && swaync-client -c 2>/dev/null || printf 0"]
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: barWindow
      required property var modelData

      screen: modelData
      color: "transparent"
      implicitHeight: 86
      exclusiveZone: 44
      mask: Region {
        x: 0
        y: 0
        width: barWindow.width
        height: barWindow.exclusiveZone
      }
      anchors {
        top: true
        left: true
        right: true
      }

      Item {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 8

        Row {
          anchors.left: parent.left
          spacing: 8

          Bubble {
            colors: theme
            fontFamily: root.fontFamily
            label: ""
            minWidth: 58
            textPixelSize: 19
            bold: true
            color: theme.surface
            labelColor: theme.primary
          }

          VoxTypeIndicator {
            colors: theme
            fontFamily: root.fontFamily
            status: root.parseJson(voxtype.text, "{}")
          }

          ActionBubble {
            colors: theme
            fontFamily: root.fontFamily
            visible: mediaStatus.text === "Playing"
            minWidth: 260
            horizontalPadding: 10
            label: (mediaStatus.text === "Playing" ? "⏸  " : "▶  ") + mediaTitle.text
            command: ["playerctl", "play-pause"]
          }

          Bubble {
            colors: theme
            fontFamily: root.fontFamily
            minWidth: 74
            label: weather.text || "meteo"
            labelColor: theme.secondary
          }
        }

        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 8

          Bubble {
            colors: theme
            fontFamily: root.fontFamily
            label: clock.date.toLocaleString(Qt.locale("fr_FR"), "ddd HH:mm")
            bold: true
          }

          Rectangle {
            implicitHeight: 34
            implicitWidth: workspaceRow.implicitWidth + 16
            radius: 999
            color: theme.bg

            RowLayout {
              id: workspaceRow
              anchors.centerIn: parent
              spacing: 0

              Repeater {
                model: root.workspaces
                WorkspaceButton {
                  required property var modelData
                  colors: theme
                  fontFamily: root.fontFamily
                  workspaceId: modelData.id
                  workspaceLabel: modelData.label
                  activeWorkspaceText: activeWorkspace.text
                }
              }
            }
          }
        }

        Row {
          anchors.right: parent.right
          spacing: 8

          TrayBubble {
            colors: theme
            parentWindow: barWindow
          }

          IconTextBubble {
            colors: theme
            fontFamily: root.fontFamily
            visible: volume.text.length > 0
            icon: ""
            label: volume.text
            shellCommand: "ghostty --class=com.mitchellh.ghostty.wiremix -e wiremix"
          }

          IconTextBubble {
            colors: theme
            fontFamily: root.fontFamily
            icon: network.text === "ETH" ? "󰈀" : ""
            label: network.text === "ETH" ? "ethernet" : network.text === "OFF" || network.text.length === 0 ? "off" : network.text
            shellCommand: "ghostty --class=com.mitchellh.ghostty.impala -e impala"
          }

          IconTextBubble {
            property string bluetoothState: bluetooth.text.split("|")[0] || "off"
            property string bluetoothLabel: bluetooth.text.split("|")[1] || "off"

            colors: theme
            fontFamily: root.fontFamily
            icon: bluetoothState === "connected" ? "󰂱" : bluetoothState === "on" ? "󰂯" : "󰂲"
            iconColor: bluetoothState === "connected" ? theme.secondary : bluetoothState === "on" ? theme.primary : theme.muted
            label: bluetoothLabel
            scrollLabel: bluetoothState === "connected"
            labelMaxWidth: 116
            shellCommand: "ghostty --class=com.mitchellh.ghostty.bluetui -e bluetui"
          }

          IconTextBubble {
            colors: theme
            fontFamily: root.fontFamily
            visible: battery.text.length > 0
            icon: battery.text.split("|")[0] || ""
            label: battery.text.split("|")[1] || ""
          }

          IconTextBubble {
            colors: theme
            fontFamily: root.fontFamily
            icon: Number(notifications.text || "0") > 0 ? "󱅫" : ""
            label: Number(notifications.text || "0") > 0 ? notifications.text : ""
            shellCommand: "swaync-client -t -sw"
          }
        }
      }
    }
  }
}
