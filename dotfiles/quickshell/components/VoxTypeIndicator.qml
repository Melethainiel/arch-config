import QtQuick
import Quickshell

Rectangle {
  id: voxIndicator

  required property var colors
  required property var parentWindow
  property string fontFamily: "JetBrainsMono Nerd Font"
  property var status: ({})
  property string statusClass: String(status.class || "")
  property bool recording: statusClass.indexOf("record") >= 0
  property bool transcribing: statusClass.indexOf("transcrib") >= 0
  property bool unavailable: statusClass === "missing" || statusClass === "setup" || statusClass === "stopped"
  property bool active: recording || transcribing
  property bool open: false
  readonly property color accent: transcribing ? colors.tertiary : unavailable ? colors.muted : colors.primary

  function titleForStatus() {
    if (recording)
      return "Voxtype ecoute"
    if (transcribing)
      return "Transcription"
    if (statusClass === "setup")
      return "Modele manquant"
    if (statusClass === "missing")
      return "Voxtype absent"
    if (statusClass === "stopped")
      return "Service arrete"
    return "Voxtype pret"
  }

  function detailForStatus() {
    if (String(status.tooltip || "").length > 0)
      return String(status.tooltip)
    if (recording)
      return "Parle, je prends les notes."
    if (transcribing)
      return "Whisper transforme l'audio en texte."
    if (unavailable)
      return "Ouvre le setup ou verifie le service utilisateur."
    return "Micro local, transcription locale."
  }

  function fieldValue(primary, fallback) {
    return String(primary || fallback)
  }

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
    color: colors.bg

    Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: 180 } }
  }

  Text {
    id: voxIcon
    anchors.horizontalCenter: parent.horizontalCenter
    y: 9
    text: voxIndicator.unavailable ? (voxIndicator.statusClass === "setup" ? " setup" : voxIndicator.statusClass === "missing" ? " missing" : " off") : ""
    color: voxIndicator.unavailable ? colors.muted : voxIndicator.transcribing ? colors.tertiary : colors.primary
    font.family: voxIndicator.fontFamily
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
    color: Qt.rgba(colors.bg.r, colors.bg.g, colors.bg.b, 1)
    border.width: 1
    border.color: voxIndicator.recording ? Qt.rgba(colors.primary.r, colors.primary.g, colors.primary.b, 0.52) : Qt.rgba(colors.tertiary.r, colors.tertiary.g, colors.tertiary.b, 0.52)
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
          color: voxIndicator.transcribing ? colors.tertiary : colors.primary
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
    anchors.horizontalCenter: parent.horizontalCenter
    y: 0
    width: voxBubble.width
    height: voxBubble.height
    cursorShape: Qt.PointingHandCursor
    onClicked: voxIndicator.open = !voxIndicator.open
  }

  PopupWindow {
    id: voxWindow

    visible: voxIndicator.open
    implicitWidth: 328
    implicitHeight: 216
    color: "transparent"
    grabFocus: true

    anchor.window: voxIndicator.parentWindow
    anchor.rect.x: Math.round(voxBubble.mapToItem(null, 0, 0).x - 18)
    anchor.rect.y: Math.round(voxBubble.mapToItem(null, 0, 0).y + 52)

    onVisibleChanged: {
      if (!visible)
        voxIndicator.open = false
    }

    Rectangle {
      anchors.fill: parent
      radius: 20
      color: colors.surface
      border.width: 1
      border.color: Qt.rgba(voxIndicator.accent.r, voxIndicator.accent.g, voxIndicator.accent.b, 0.42)
      clip: true

      Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Row {
          width: parent.width
          spacing: 12

          Rectangle {
            width: 42
            height: 42
            radius: 999
            color: Qt.rgba(voxIndicator.accent.r, voxIndicator.accent.g, voxIndicator.accent.b, 0.16)
            border.width: 1
            border.color: Qt.rgba(voxIndicator.accent.r, voxIndicator.accent.g, voxIndicator.accent.b, 0.42)

            Text {
              anchors.centerIn: parent
              text: voxIndicator.transcribing ? "󰦨" : voxIndicator.unavailable ? "" : ""
              color: voxIndicator.accent
              font.family: voxIndicator.fontFamily
              font.pixelSize: 18
            }
          }

          Column {
            width: parent.width - 54
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Text {
              width: parent.width
              text: voxIndicator.titleForStatus()
              color: colors.textStrong
              font.family: voxIndicator.fontFamily
              font.pixelSize: 15
              font.bold: true
              elide: Text.ElideRight
            }

            Text {
              width: parent.width
              text: voxIndicator.detailForStatus()
              color: colors.text
              font.family: voxIndicator.fontFamily
              font.pixelSize: 11
              elide: Text.ElideRight
            }
          }
        }

        Row {
          width: parent.width
          spacing: 8

          Rectangle {
            width: 92
            height: 46
            radius: 14
            color: colors.surfaceHover
            clip: true

            Item {
              anchors.fill: parent

              Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 16
                spacing: 2

                Text { width: parent.width; height: 12; text: "modele"; color: colors.text; opacity: 0.74; font.family: voxIndicator.fontFamily; font.pixelSize: 9; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight; lineHeightMode: Text.FixedHeight; lineHeight: 12 }
                Text { width: parent.width; height: 14; text: voxIndicator.fieldValue(status.model, "local"); color: colors.textStrong; font.family: voxIndicator.fontFamily; font.pixelSize: 11; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight; lineHeightMode: Text.FixedHeight; lineHeight: 14 }
              }
            }
          }

          Rectangle {
            width: 92
            height: 46
            radius: 14
            color: colors.surfaceHover
            clip: true

            Item {
              anchors.fill: parent

              Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 16
                spacing: 2

                Text { width: parent.width; height: 12; text: "moteur"; color: colors.text; opacity: 0.74; font.family: voxIndicator.fontFamily; font.pixelSize: 9; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight; lineHeightMode: Text.FixedHeight; lineHeight: 12 }
                Text { width: parent.width; height: 14; text: voxIndicator.fieldValue(status.engine || status.backend, "whisper"); color: colors.textStrong; font.family: voxIndicator.fontFamily; font.pixelSize: 11; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight; lineHeightMode: Text.FixedHeight; lineHeight: 14 }
              }
            }
          }

          Rectangle {
            width: 92
            height: 46
            radius: 14
            color: colors.surfaceHover
            clip: true

            Item {
              anchors.fill: parent

              Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 16
                spacing: 2

                Text { width: parent.width; height: 12; text: "hotkey"; color: colors.text; opacity: 0.74; font.family: voxIndicator.fontFamily; font.pixelSize: 9; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight; lineHeightMode: Text.FixedHeight; lineHeight: 12 }
                Text { width: parent.width; height: 14; text: voxIndicator.fieldValue(status.hotkey, "Super+V"); color: colors.textStrong; font.family: voxIndicator.fontFamily; font.pixelSize: 10; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight; lineHeightMode: Text.FixedHeight; lineHeight: 14 }
              }
            }
          }
        }

        Row {
          width: parent.width
          spacing: 8

          Rectangle {
            width: 92
            height: 34
            radius: 999
            color: Qt.rgba(colors.primary.r, colors.primary.g, colors.primary.b, 0.16)
            border.width: 1
            border.color: Qt.rgba(colors.primary.r, colors.primary.g, colors.primary.b, 0.36)

            Text { anchors.centerIn: parent; text: "setup"; color: colors.textStrong; font.family: voxIndicator.fontFamily; font.pixelSize: 11; font.bold: true }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["sh", "-c", "ghostty --class=com.mitchellh.ghostty.voxtype -e bash -lc \"voxtype configure; read -n1 -r -p 'Press any key to close'\""]) }
          }

          Rectangle {
            width: 92
            height: 34
            radius: 999
            color: Qt.rgba(colors.tertiary.r, colors.tertiary.g, colors.tertiary.b, 0.16)
            border.width: 1
            border.color: Qt.rgba(colors.tertiary.r, colors.tertiary.g, colors.tertiary.b, 0.36)

            Text { anchors.centerIn: parent; text: "restart"; color: colors.textStrong; font.family: voxIndicator.fontFamily; font.pixelSize: 11; font.bold: true }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["sh", "-c", "systemctl --user restart voxtype.service 2>/dev/null || true"]) }
          }

          Rectangle {
            width: 92
            height: 34
            radius: 999
            color: Qt.rgba(colors.secondary.r, colors.secondary.g, colors.secondary.b, 0.16)
            border.width: 1
            border.color: Qt.rgba(colors.secondary.r, colors.secondary.g, colors.secondary.b, 0.36)

            Text { anchors.centerIn: parent; text: "logs"; color: colors.textStrong; font.family: voxIndicator.fontFamily; font.pixelSize: 11; font.bold: true }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["sh", "-c", "ghostty --class=com.mitchellh.ghostty.voxtype-logs -e bash -lc \"voxtype status --extended 2>/dev/null || true; printf '\\\\n--- journal ---\\\\n'; journalctl --user -u voxtype.service -n 80 --no-pager 2>/dev/null || true; read -n1 -r -p 'Press any key to close'\""]) }
          }
        }
      }
    }
  }
}
