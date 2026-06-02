import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Widgets

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

  function run(command) {
    Quickshell.execDetached(command)
  }

  function runShell(command) {
    Quickshell.execDetached(["sh", "-c", command])
  }

  function parseJson(text, fallback) {
    try {
      return JSON.parse(text || fallback)
    } catch (error) {
      return JSON.parse(fallback)
    }
  }

  Theme { id: theme }

  component CommandPoller: QtObject {
    id: poller

    property var command: []
    property int interval: 1000
    property string text: ""

    function refresh() {
      if (!process.running)
        process.exec()
    }

    Component.onCompleted: refresh()

    Timer {
      interval: poller.interval
      repeat: true
      running: true
      triggeredOnStart: false
      onTriggered: poller.refresh()
    }

    Process {
      id: process
      command: poller.command
      stdout: StdioCollector {
        onStreamFinished: poller.text = text.trim()
      }
    }
  }

  component Bubble: Rectangle {
    id: bubble

    property alias label: bubbleText.text
    property color labelColor: theme.text
    property int horizontalPadding: 12
    property int minWidth: 0
    property int textPixelSize: 13
    property bool bold: false

    implicitWidth: Math.max(minWidth, bubbleText.implicitWidth + horizontalPadding * 2)
    implicitHeight: 34
    radius: 999
    color: theme.bg

    Text {
      id: bubbleText
      anchors.centerIn: parent
      color: bubble.labelColor
      font.family: "JetBrainsMono Nerd Font, Font Awesome 6 Free, Noto Sans"
      font.pixelSize: bubble.textPixelSize
      font.bold: bubble.bold
      verticalAlignment: Text.AlignVCenter
      elide: Text.ElideRight
    }
  }

  component ActionBubble: Bubble {
    id: actionBubble

    property var command: []
    property string shellCommand: ""

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: actionBubble.shellCommand.length > 0 ? root.runShell(actionBubble.shellCommand) : root.run(actionBubble.command)
    }
  }

  component WorkspaceButton: Rectangle {
    id: workspaceButton

    required property int workspaceId
    required property string workspaceLabel
    property bool active: activeWorkspace.text === String(workspaceId)

    Layout.preferredWidth: active ? 44 : 34
    Layout.preferredHeight: 34
    radius: 999
    color: "transparent"

    Rectangle {
      anchors.centerIn: parent
      width: parent.active ? 44 : 28
      height: 20
      radius: 999
      color: parent.active ? theme.primary : theme.surfaceDim

      Text {
        anchors.centerIn: parent
        text: workspaceButton.workspaceLabel
        color: workspaceButton.active ? theme.onPrimary : theme.muted
        font.family: "JetBrainsMono Nerd Font, Font Awesome 6 Free, Noto Sans"
        font.pixelSize: 13
        verticalAlignment: Text.AlignVCenter
      }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: root.run(["hyprctl", "dispatch", "workspace", String(workspaceButton.workspaceId)])
    }
  }

  component TrayBubble: Rectangle {
    id: trayBubble

    property var parentWindow

    implicitHeight: 34
    implicitWidth: trayRow.implicitWidth + 16
    radius: 999
    color: theme.bg
    visible: SystemTray.items.values.length > 0

    Row {
      id: trayRow
      anchors.centerIn: parent
      spacing: 4

      Repeater {
        model: SystemTray.items

        MouseArea {
          id: trayItem
          required property var modelData

          width: 24
          height: 34
          acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
          cursorShape: Qt.PointingHandCursor
          hoverEnabled: true

          Rectangle {
            anchors.fill: parent
            radius: 999
            color: trayItem.containsMouse ? theme.surfaceHover : "transparent"
          }

          IconImage {
            anchors.centerIn: parent
            source: trayItem.modelData.icon
            implicitSize: 16
          }

          onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton && modelData.hasMenu)
              modelData.display(trayBubble.parentWindow, x, y + height)
            else if (mouse.button === Qt.MiddleButton)
              modelData.secondaryActivate()
            else if (modelData.onlyMenu && modelData.hasMenu)
              modelData.display(trayBubble.parentWindow, x, y + height)
            else
              modelData.activate()
          }
        }
      }
    }
  }

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
    id: battery
    interval: 5000
    command: ["sh", "-c", "dev=$(upower -e 2>/dev/null | grep -m1 battery || true); if [ -n \"$dev\" ]; then pct=$(upower -i \"$dev\" | sed -n 's/^[[:space:]]*percentage:[[:space:]]*//p' | head -n1); state=$(upower -i \"$dev\" | sed -n 's/^[[:space:]]*state:[[:space:]]*//p' | head -n1); [ -z \"$pct\" ] && exit 0; case \"$state\" in charging) icon= ;; fully-charged) icon= ;; discharging) icon= ;; *) icon= ;; esac; printf '%s %s' \"$icon\" \"$pct\"; fi"]
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
      implicitHeight: 50
      exclusiveZone: 50
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
            label: ""
            minWidth: 58
            textPixelSize: 19
            bold: true
            color: theme.surface
            labelColor: theme.primary
          }

          ActionBubble {
            property var status: root.parseJson(voxtype.text, "{}")
            label: status.class === "missing" ? " missing" : status.class === "setup" ? " setup" : status.class === "stopped" ? " off" : String(status.class || "").indexOf("record") >= 0 ? " rec" : String(status.class || "").indexOf("transcrib") >= 0 ? " txt" : ""
            labelColor: status.class === "setup" || status.class === "stopped" || status.class === "missing" ? theme.muted : String(status.class || "").indexOf("transcrib") >= 0 ? theme.tertiary : theme.primary
            color: String(status.class || "").indexOf("record") >= 0 ? theme.primary : theme.bg
            shellCommand: "ghostty --class=com.mitchellh.ghostty.voxtype -e bash -lc \"arch-setup-voxtype; read -n1 -r -p 'Press any key to close'\""
          }

          ActionBubble {
            visible: mediaStatus.text !== "Stopped"
            minWidth: 260
            horizontalPadding: 10
            label: (mediaStatus.text === "Playing" ? "⏸  " : "▶  ") + mediaTitle.text
            command: ["playerctl", "play-pause"]
          }

          Bubble {
            minWidth: 74
            label: weather.text || "meteo"
            labelColor: theme.secondary
          }
        }

        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 8

          Bubble {
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
                  workspaceId: modelData.id
                  workspaceLabel: modelData.label
                }
              }
            }
          }
        }

        Row {
          anchors.right: parent.right
          spacing: 8

          TrayBubble { parentWindow: barWindow }

          ActionBubble {
            visible: volume.text.length > 0
            label: " " + volume.text
            shellCommand: "ghostty --class=com.mitchellh.ghostty.wiremix -e wiremix"
          }

          ActionBubble {
            label: network.text === "ETH" ? "󰈀 ethernet" : network.text === "OFF" || network.text.length === 0 ? " off" : " " + network.text
            shellCommand: "ghostty --class=com.mitchellh.ghostty.impala -e impala"
          }

          Bubble {
            visible: battery.text.length > 0
            label: battery.text
          }

          ActionBubble {
            label: Number(notifications.text || "0") > 0 ? "󱅫 " + notifications.text : ""
            shellCommand: "swaync-client -t -sw"
          }
        }
      }
    }
  }
}
