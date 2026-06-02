import QtQuick
import Quickshell

Rectangle {
  id: voxIndicator

  required property var colors
  property string fontFamily: "JetBrainsMono Nerd Font"
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
    onClicked: Quickshell.execDetached(["sh", "-c", "ghostty --class=com.mitchellh.ghostty.voxtype -e bash -lc \"arch-setup-voxtype; read -n1 -r -p 'Press any key to close'\""])
  }
}
