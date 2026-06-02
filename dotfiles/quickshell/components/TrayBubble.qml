import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Rectangle {
  id: trayBubble

  required property var colors
  property var parentWindow

  implicitHeight: 34
  implicitWidth: trayRow.implicitWidth + 16
  radius: 999
  color: colors.bg
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
          color: trayItem.containsMouse ? colors.surfaceHover : "transparent"
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
