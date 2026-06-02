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

  component CommandPoller: Item {
    id: poller

    property var command: []
    property int interval: 1000
    property string text: ""

    visible: false

    function refresh() {
      if (!process.running)
        process.exec(poller.command)
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

  component VoxTypeIndicator: Rectangle {
    id: voxIndicator

    property var status: ({})
    property string statusClass: String(status.class || "")
    property bool recording: statusClass.indexOf("record") >= 0
    property bool transcribing: statusClass.indexOf("transcrib") >= 0
    property bool unavailable: statusClass === "missing" || statusClass === "setup" || statusClass === "stopped"
    property bool active: recording || transcribing

    implicitWidth: unavailable ? 92 : 34
    implicitHeight: active ? 79 : 34
    color: "transparent"

    Behavior on implicitWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    Rectangle {
      id: voxBubble
      anchors.horizontalCenter: parent.horizontalCenter
      y: 0
      width: voxIndicator.unavailable ? parent.width : 34
      height: 34
      radius: 999
      color: theme.bg

      Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
      Behavior on color { ColorAnimation { duration: 180 } }
    }

    Text {
      id: voxIcon
      anchors.horizontalCenter: parent.horizontalCenter
      y: 9
      text: voxIndicator.unavailable ? (voxIndicator.statusClass === "setup" ? " setup" : voxIndicator.statusClass === "missing" ? " missing" : " off") : ""
      color: voxIndicator.unavailable ? theme.muted : voxIndicator.transcribing ? theme.tertiary : theme.primary
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: voxIndicator.unavailable ? 13 : 14
      verticalAlignment: Text.AlignVCenter

      Behavior on color { ColorAnimation { duration: 180 } }
    }

    Rectangle {
      id: voxActivity
      anchors.horizontalCenter: parent.horizontalCenter
      y: 36
      width: 82
      height: 40
      radius: 12
      clip: true
      opacity: voxIndicator.active ? 1 : 0
      color: Qt.rgba(theme.bg.r, theme.bg.g, theme.bg.b, 1)
      border.width: 1
      border.color: voxIndicator.recording ? Qt.rgba(theme.primary.r, theme.primary.g, theme.primary.b, 0.52) : Qt.rgba(theme.tertiary.r, theme.tertiary.g, theme.tertiary.b, 0.52)
      scale: voxIndicator.active ? 1 : 0.68

      Behavior on opacity { NumberAnimation { duration: 140 } }
      Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

      Row {
        anchors.centerIn: parent
        spacing: 3

        Repeater {
          model: 5

          Rectangle {
            id: voxWave
            width: voxIndicator.transcribing ? 6 : 5
            height: voxIndicator.transcribing ? 6 : 10 + (index % 3) * 6
            radius: 999
            color: voxIndicator.transcribing ? theme.tertiary : theme.primary
            opacity: voxIndicator.active ? 1 : 0
            transformOrigin: Item.Center

            SequentialAnimation on scale {
              running: voxIndicator.recording
              loops: Animation.Infinite
              PauseAnimation { duration: index * 70 }
              NumberAnimation { to: 1.35; duration: 220; easing.type: Easing.InOutSine }
              NumberAnimation { to: 0.75; duration: 260; easing.type: Easing.InOutSine }
            }

            SequentialAnimation on opacity {
              running: voxIndicator.transcribing
              loops: Animation.Infinite
              PauseAnimation { duration: index * 90 }
              NumberAnimation { to: 0.35; duration: 180; easing.type: Easing.InOutSine }
              NumberAnimation { to: 1; duration: 180; easing.type: Easing.InOutSine }
            }

            Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 160 } }
          }
        }
      }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: root.runShell("ghostty --class=com.mitchellh.ghostty.voxtype -e bash -lc \"arch-setup-voxtype; read -n1 -r -p 'Press any key to close'\"")
    }
  }

  component IconTextBubble: Rectangle {
    id: iconTextBubble

    property string icon: ""
    property string label: ""
    property color iconColor: theme.text
    property color labelColor: theme.text
    property var command: []
    property string shellCommand: ""
    property int horizontalPadding: 12
    property int minWidth: 0
    property bool scrollLabel: false
    property int labelMaxWidth: 110

    implicitWidth: Math.max(minWidth, iconTextRow.implicitWidth + horizontalPadding * 2)
    implicitHeight: 34
    radius: 999
    color: theme.bg

    Row {
      id: iconTextRow
      anchors.centerIn: parent
      spacing: 6

      Text {
        text: iconTextBubble.icon
        color: iconTextBubble.iconColor
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
        verticalAlignment: Text.AlignVCenter
      }

      Item {
        id: labelClip

        property bool overflow: iconTextBubble.scrollLabel && labelText.implicitWidth > iconTextBubble.labelMaxWidth

        implicitWidth: overflow ? iconTextBubble.labelMaxWidth : labelText.implicitWidth
        implicitHeight: labelText.implicitHeight
        clip: overflow

        onOverflowChanged: labelText.x = 0
        onImplicitWidthChanged: labelText.x = 0

        Text {
          id: labelText

          anchors.verticalCenter: parent.verticalCenter
          text: iconTextBubble.label
          color: iconTextBubble.labelColor
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 13
          verticalAlignment: Text.AlignVCenter
        }

        SequentialAnimation {
          running: labelClip.overflow
          loops: Animation.Infinite

          PropertyAction { target: labelText; property: "x"; value: 0 }
          PauseAnimation { duration: 900 }
          NumberAnimation {
            target: labelText
            property: "x"
            to: -Math.max(0, labelText.implicitWidth - labelClip.implicitWidth)
            duration: Math.max(1200, (labelText.implicitWidth - labelClip.implicitWidth) * 45)
            easing.type: Easing.InOutSine
          }
          PauseAnimation { duration: 900 }
        }
      }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: iconTextBubble.shellCommand.length > 0 || iconTextBubble.command.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: {
        if (iconTextBubble.shellCommand.length > 0)
          root.runShell(iconTextBubble.shellCommand)
        else if (iconTextBubble.command.length > 0)
          root.run(iconTextBubble.command)
      }
    }
  }

  component WorkspaceButton: Rectangle {
    id: workspaceButton

    required property int workspaceId
    required property string workspaceLabel
    property bool active: activeWorkspace.text === String(workspaceId)
    property string workspaceIcon: workspaceLabel.indexOf(" ") > 0 ? workspaceLabel.split(" ")[0] : ""
    property string workspaceText: workspaceLabel.indexOf(" ") > 0 ? workspaceLabel.split(" ").slice(1).join(" ") : workspaceLabel

    Layout.preferredWidth: active ? 50 : 40
    Layout.preferredHeight: 34
    radius: 999
    color: "transparent"

    Rectangle {
      anchors.centerIn: parent
      width: parent.active ? 44 : 34
      height: 20
      radius: 999
      color: parent.active ? theme.primary : theme.surfaceDim

      Row {
        anchors.centerIn: parent
        spacing: 3

        Text {
          visible: workspaceButton.workspaceIcon.length > 0
          text: workspaceButton.workspaceIcon
          color: workspaceButton.active ? theme.primaryText : theme.muted
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 13
          verticalAlignment: Text.AlignVCenter
        }

        Text {
          text: workspaceButton.workspaceText
          color: workspaceButton.active ? theme.primaryText : theme.muted
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 13
          verticalAlignment: Text.AlignVCenter
        }
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

          VoxTypeIndicator {
            status: root.parseJson(voxtype.text, "{}")
          }

          ActionBubble {
            visible: mediaStatus.text === "Playing"
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

          IconTextBubble {
            visible: volume.text.length > 0
            icon: ""
            label: volume.text
            shellCommand: "ghostty --class=com.mitchellh.ghostty.wiremix -e wiremix"
          }

          IconTextBubble {
            icon: network.text === "ETH" ? "󰈀" : ""
            label: network.text === "ETH" ? "ethernet" : network.text === "OFF" || network.text.length === 0 ? "off" : network.text
            shellCommand: "ghostty --class=com.mitchellh.ghostty.impala -e impala"
          }

          IconTextBubble {
            property string bluetoothState: bluetooth.text.split("|")[0] || "off"
            property string bluetoothLabel: bluetooth.text.split("|")[1] || "off"

            icon: bluetoothState === "connected" ? "󰂱" : bluetoothState === "on" ? "󰂯" : "󰂲"
            iconColor: bluetoothState === "connected" ? theme.secondary : bluetoothState === "on" ? theme.primary : theme.muted
            label: bluetoothLabel
            scrollLabel: bluetoothState === "connected"
            labelMaxWidth: 116
            shellCommand: "ghostty --class=com.mitchellh.ghostty.bluetui -e bluetui"
          }

          IconTextBubble {
            visible: battery.text.length > 0
            icon: battery.text.split("|")[0] || ""
            label: battery.text.split("|")[1] || ""
          }

          IconTextBubble {
            icon: Number(notifications.text || "0") > 0 ? "󱅫" : ""
            label: Number(notifications.text || "0") > 0 ? notifications.text : ""
            shellCommand: "swaync-client -t -sw"
          }
        }
      }
    }
  }
}
