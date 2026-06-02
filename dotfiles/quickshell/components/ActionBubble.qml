import QtQuick
import Quickshell

Bubble {
  id: actionBubble

  property var command: []
  property string shellCommand: ""

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: shellCommand.length > 0 ? Quickshell.execDetached(["sh", "-c", shellCommand]) : Quickshell.execDetached(command)
  }
}
