import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

// Menu contextuel DBus (SNI) rendu en QML natif dans un PopupWindow, thématique
// colors.surface / colors.text au lieu du menu Qt blanc par défaut.
// Hiérarchie: PopupWindow > Rectangle (panneau) > Column (page courante).
// Navigation sous-menu: pile JS d Handles (root.menuStack). Chaque QsMenuEntry
// ayant hasChildren est lui-même un QsMenuHandle valide pour un QsMenuOpener.
// On évite QtQuick.Controls (StackView) pour ne pas importer le styling Controls.
PopupWindow {
  id: root

  required property var colors
  required property string fontFamily
  required property var parentWindow
  required property var menuHandle
  required property var anchorItem

  property bool open: false
  property var menuStack: [] // pile de QsMenuEntry (sous-menus empilés)
  readonly property var currentHandle: menuStack.length > 0 ? menuStack[menuStack.length - 1] : null

  implicitWidth: 276
  implicitHeight: menuPanel.implicitHeight + 16
  color: "transparent"
  grabFocus: true

  anchor.window: root.parentWindow
  anchor.item: root.anchorItem
  anchor.edges: Edges.Bottom | Edges.Left
  anchor.gravity: Edges.Bottom | Edges.Right
  anchor.adjustment: PopupAdjustment.Flip | PopupAdjustment.SlideX | PopupAdjustment.ResizeY
  anchor.margins.top: 6

  onOpenChanged: root.visible = root.open

  // Fermeture externe (clic hors menu, Escape) → resync open + collapse cascade.
  onVisibleChanged: {
    if (visible) return
    root.open = false
    if (menuStack.length > 0) menuStack = []
  }

  // Navigation: on réassigne le tableau (nouvelle référence) pour déclencher
  // la réévaluation des bindings qui dépendent de menuStack / currentHandle.
  function pushSubMenu(handle) {
    menuStack = menuStack.concat(handle)
  }

  function popSubMenu() {
    if (menuStack.length === 0) return
    menuStack = menuStack.slice(0, -1)
  }

  QsMenuOpener {
    id: rootOpener
    menu: root.menuHandle
  }

  // Ouvre le sous-menu courant. null sur la page racine → children vide, le
  // Repeater bascule sur rootOpener.children via le ternaire.
  QsMenuOpener {
    id: subOpener
    menu: root.currentHandle
  }

  Rectangle {
    id: menuPanel
    anchors.fill: parent
    anchors.margins: 8
    radius: 16
    color: root.colors.surface
    border.width: 1
    border.color: Qt.rgba(root.colors.text.r, root.colors.text.g, root.colors.text.b, 0.12)
    clip: true

    implicitHeight: pageContent.implicitHeight + 16

    Column {
      id: pageContent
      anchors.fill: parent
      anchors.margins: 8
      spacing: 2

      // Bouton retour (sous-menus uniquement)
      Item {
        width: pageContent.width
        height: 28
        visible: root.currentHandle !== null

        Text {
          anchors.left: parent.left
          anchors.leftMargin: 8
          anchors.verticalCenter: parent.verticalCenter
          text: "‹ retour"
          color: root.colors.muted
          font.family: root.fontFamily
          font.pixelSize: 11
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.popSubMenu()
        }
      }

      Repeater {
        model: root.currentHandle ? subOpener.children : rootOpener.children
        delegate: menuEntryDelegate
      }
    }
  }

  // Délégué d'entrée: sépare les 4 cas (separator / feuille / sous-menu /
  // désactivé) via des bindings de visibilité plutôt que des Loaders.
  Component {
    id: menuEntryDelegate

    Item {
      id: entry
      required property QsMenuEntry modelData

      width: parent.width
      height: entry.modelData.isSeparator ? 9 : 32

      // Séparateur: ligne fine centrée, pas d'interaction
      Rectangle {
        visible: entry.modelData.isSeparator
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Qt.rgba(root.colors.text.r, root.colors.text.g, root.colors.text.b, 0.1)
      }

      // Fond hover (entrées non-séparateur uniquement)
      Rectangle {
        visible: !entry.modelData.isSeparator
        anchors.fill: parent
        radius: 6
        color: entryMouse.containsMouse && entry.modelData.enabled
          ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.18)
          : "transparent"
        Behavior on color { ColorAnimation { duration: 140 } }
      }

      // Contenu: [indicateur | icône] label [chevron]
      RowLayout {
        visible: !entry.modelData.isSeparator
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8

        // Indicateur checkbox / radio
        Text {
          Layout.preferredWidth: 18
          horizontalAlignment: Text.AlignHCenter
          visible: entry.modelData.buttonType !== QsMenuButtonType.None
          color: root.colors.secondary
          font.family: root.fontFamily
          font.pixelSize: 13
          text: entry.modelData.buttonType === QsMenuButtonType.CheckBox
            ? (entry.modelData.checkState === Qt.Checked ? "☑" : "☐")
            : (entry.modelData.checkState === Qt.Checked ? "◉" : "○")
        }

        // Icône DBus (seulement si pas d'indicateur et icône non vide)
        IconImage {
          Layout.preferredWidth: 16
          Layout.preferredHeight: 16
          visible: entry.modelData.buttonType === QsMenuButtonType.None
            && entry.modelData.icon.toString().length > 0
          source: entry.modelData.icon
          implicitSize: 16
        }

        // Label (mnémoniques & stripés)
        Text {
          Layout.fillWidth: true
          color: entry.modelData.enabled ? root.colors.text : root.colors.muted
          font.family: root.fontFamily
          font.pixelSize: 13
          elide: Text.ElideRight
          text: entry.modelData.text.replace(/&/g, "")
        }

        // Chevron sous-menu
        Text {
          Layout.preferredWidth: 12
          horizontalAlignment: Text.AlignRight
          visible: entry.modelData.hasChildren
          color: root.colors.muted
          font.family: root.fontFamily
          font.pixelSize: 13
          text: "›"
        }
      }

      // Clic: sous-menu → push, feuille → triggered + fermeture.
      // `triggered` est un signal QsMenuEntry; Qt QML autorise l'émission
      // d'un signal en l'invoquant comme méthode (cf. doc Qt 6). C'est la
      // seule API publique: sendTriggered() est privé sur DBusMenuItem et
      // n'est pas exposé à QML — l'appeler ne fait rien.
      MouseArea {
        id: entryMouse
        anchors.fill: parent
        hoverEnabled: true
        visible: !entry.modelData.isSeparator
        enabled: entry.modelData.enabled
        cursorShape: entry.modelData.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

        onClicked: {
          if (entry.modelData.hasChildren) {
            root.pushSubMenu(entry.modelData)
            return
          }
          entry.modelData.triggered()
          root.open = false
        }
      }
    }
  }
}
