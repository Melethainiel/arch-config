import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
  id: workspaceButton

  required property var colors
  property string fontFamily: "JetBrainsMono Nerd Font"
  required property int workspaceId
  required property string workspaceLabel
  property string activeWorkspaceText: ""
  property bool active: activeWorkspaceText === String(workspaceId)
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
    color: parent.active ? "transparent" : colors.surfaceDim

    Row {
      anchors.centerIn: parent
      spacing: 3

      Text {
        visible: workspaceButton.workspaceIcon.length > 0
        text: workspaceButton.workspaceIcon
        color: workspaceButton.active ? colors.primaryText : colors.muted
        font.family: workspaceButton.fontFamily
        font.pixelSize: 13
        verticalAlignment: Text.AlignVCenter
      }

      Text {
        text: workspaceButton.workspaceText
        color: workspaceButton.active ? colors.primaryText : colors.muted
        font.family: workspaceButton.fontFamily
        font.pixelSize: 13
        verticalAlignment: Text.AlignVCenter
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "workspace", String(workspaceButton.workspaceId)])
  }
}
