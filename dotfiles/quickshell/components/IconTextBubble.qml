import QtQuick
import Quickshell

Rectangle {
  id: iconTextBubble

  required property var colors
  property string fontFamily: "JetBrainsMono Nerd Font"
  property string icon: ""
  property string label: ""
  property color iconColor: colors.text
  property color labelColor: colors.text
  property var command: []
  property string shellCommand: ""
  property int horizontalPadding: 12
  property int minWidth: 0
  property bool scrollLabel: false
  property int labelMaxWidth: 110

  implicitWidth: Math.max(minWidth, iconTextRow.implicitWidth + horizontalPadding * 2)
  implicitHeight: 34
  radius: 999
  color: colors.bg

  Row {
    id: iconTextRow
    anchors.centerIn: parent
    spacing: 6

    Text {
      text: iconTextBubble.icon
      color: iconTextBubble.iconColor
      font.family: iconTextBubble.fontFamily
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
        font.family: iconTextBubble.fontFamily
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
    cursorShape: shellCommand.length > 0 || command.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: {
      if (shellCommand.length > 0)
        Quickshell.execDetached(["sh", "-c", shellCommand])
      else if (command.length > 0)
        Quickshell.execDetached(command)
    }
  }
}
