import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Rectangle {
  id: trayBubble

  required property var colors
  property var parentWindow
  property string fontFamily: "JetBrainsMono Nerd Font"

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

        // Menu contextuel DBus rendu via TrayMenu (PopupWindow personnalisée),
        // thématique colors.surface / colors.text au lieu du QMenu Qt natif.
        // anchor.item laisse Quickshell calculer le rect d'ancrage depuis
        // l'item lui-même, plus fiable qu'un mapToItem(null, ...) dans un
        // contexte Variants multi-écran.
        TrayMenu {
          id: ctxMenu
          colors: trayBubble.colors
          fontFamily: trayBubble.fontFamily
          parentWindow: trayBubble.parentWindow
          menuHandle: trayItem.modelData.menu
          anchorItem: trayItem
        }

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

        // Bascule le menu contextuel si l'item expose un menu DBus non null.
        // Garde le contrôle centralisé pour éviter la duplication entre clic
        // droit et clic gauche sur les items "onlyMenu".
        function toggleMenu() {
          if (!ctxMenu.menuHandle) return
          ctxMenu.open = !ctxMenu.open
        }

        onClicked: function(mouse) {
          // Clic droit → menu contextuel (la plupart des apps SNI l'exposent).
          if (mouse.button === Qt.RightButton) {
            toggleMenu()
            return
          }

          // Clic milieu → action secondaire DBus (ex. "SecondaryActivate").
          if (mouse.button === Qt.MiddleButton) {
            trayItem.modelData.secondaryActivate()
            return
          }

          // Clic gauche → menu pour les items "onlyMenu" (ex. pure popups),
          // sinon action principale DBus (Activate).
          if (trayItem.modelData.onlyMenu) toggleMenu()
          else trayItem.modelData.activate()
        }
      }
    }
  }
}
