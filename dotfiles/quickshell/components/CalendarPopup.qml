import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

// Popup calendrier au clic sur l'horloge.
// Calque le pattern de WeatherPopup.qml : racine Rectangle transparente,
// bubble interne animee, PopupWindow pilotee via onOpenChanged (pas de binding
// direct visible: open pour eviter les glitches Wayland).
Rectangle {
  id: calendarPopup

  required property var colors
  required property var parentWindow
  property string fontFamily: "JetBrainsMono Nerd Font"
  property var clockRef
  property bool open: false
  readonly property date currentDate: clockRef ? clockRef.date : new Date()

  implicitWidth: Math.max(84, currentText.implicitWidth + 24)
  implicitHeight: 34
  color: "transparent"

  // Sync aller -> popup. Le popup signale sa fermeture via onVisibleChanged.
  onOpenChanged: calendarWindow.visible = open

  Rectangle {
    id: calendarBubble
    anchors.horizontalCenter: parent.horizontalCenter
    y: 0
    width: calendarPopup.implicitWidth
    height: 34
    radius: 999
    color: calendarPopup.open ? colors.surface : colors.bg
    border.width: calendarPopup.open ? 1 : 0
    border.color: Qt.rgba(colors.primary.r, colors.primary.g, colors.primary.b, 0.45)

    Behavior on color { ColorAnimation { duration: 160 } }
  }

  Text {
    id: currentText
    anchors.centerIn: calendarBubble
    text: calendarPopup.currentDate.toLocaleString(Qt.locale("fr_FR"), "ddd HH:mm")
    color: colors.textStrong
    font.family: calendarPopup.fontFamily
    font.pixelSize: 13
    font.bold: true
    verticalAlignment: Text.AlignVCenter
  }

  MouseArea {
    anchors.fill: calendarBubble
    cursorShape: Qt.PointingHandCursor
    onClicked: calendarPopup.open = !calendarPopup.open
  }

  PopupWindow {
    id: calendarWindow

    implicitWidth: 340
    implicitHeight: 380
    color: "transparent"
    grabFocus: true

    anchor.window: calendarPopup.parentWindow
    anchor.item: calendarBubble
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 18
    // Slide / flip hors ecran sur petites fenetres (cf. PopupAdjustment flags).
    anchor.adjustment: PopupAdjustment.SlideX | PopupAdjustment.FlipX

    onVisibleChanged: if (!visible) calendarPopup.open = false

    Rectangle {
      id: calendarPanel
      anchors.fill: parent
      radius: 18
      color: colors.surface
      border.width: 1
      border.color: Qt.rgba(colors.primary.r, colors.primary.g, colors.primary.b, 0.34)
      clip: true

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header de navigation : mois + annee avec boutons precedent / suivant.
        RowLayout {
          Layout.fillWidth: true
          spacing: 8

          Rectangle {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            radius: 999
            color: prevMonthArea.containsMouse ? colors.surfaceHover : "transparent"

            Text {
              anchors.centerIn: parent
              text: "\u2039"
              color: prevMonthArea.containsMouse ? colors.primary : colors.textStrong
              font.family: calendarPopup.fontFamily
              font.pixelSize: 16
              font.bold: true
            }

            MouseArea {
              id: prevMonthArea
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: grid.shiftMonth(-1)
            }
          }

          Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 32

            Text {
              anchors.centerIn: parent
              text: grid.month >= 0 ? Qt.locale("fr_FR").standaloneMonthName(grid.month) + " " + grid.year : ""
              color: colors.textStrong
              font.family: calendarPopup.fontFamily
              font.pixelSize: 15
              font.bold: true
            }
          }

          Rectangle {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            radius: 999
            color: nextMonthArea.containsMouse ? colors.surfaceHover : "transparent"

            Text {
              anchors.centerIn: parent
              text: "\u203A"
              color: nextMonthArea.containsMouse ? colors.primary : colors.textStrong
              font.family: calendarPopup.fontFamily
              font.pixelSize: 16
              font.bold: true
            }

            MouseArea {
              id: nextMonthArea
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: grid.shiftMonth(1)
            }
          }
        }

        // Bande des jours de la semaine (initiales fr_FR).
        DayOfWeekRow {
          Layout.fillWidth: true
          locale: Qt.locale("fr_FR")

          delegate: Text {
            text: narrowName
            color: colors.muted
            font.family: calendarPopup.fontFamily
            font.pixelSize: 11
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            required property string narrowName
          }
        }

        MonthGrid {
          id: grid
          Layout.fillWidth: true
          Layout.fillHeight: true
          locale: Qt.locale("fr_FR")
          // Init unique dans onCompleted : sans binding declaratif, shiftMonth
          // reste maitre de la position visible (pas de fleche qd le jour bascule).
          Component.onCompleted: {
            month = calendarPopup.currentDate.getMonth()
            year = calendarPopup.currentDate.getFullYear()
          }

          property date selectedDate: calendarPopup.currentDate

          function shiftMonth(delta) {
            var m = month + delta
            var y = year
            if (m < 0) { m = 11; y-- }
            if (m > 11) { m = 0; y++ }
            month = m
            year = y
          }

          delegate: Rectangle {
            implicitWidth: 36
            implicitHeight: 36
            radius: 6

            required property date date
            required property int day
            required property int month
            required property int year
            required property bool today

            readonly property bool isSelected: Qt.formatDate(date, "yyyyMMdd") === Qt.formatDate(grid.selectedDate, "yyyyMMdd")

            color: isSelected ? colors.primary
              : today ? Qt.rgba(colors.primary.r, colors.primary.g, colors.primary.b, 0.18)
              : "transparent"

            Text {
              anchors.centerIn: parent
              text: day
              color: isSelected ? colors.primaryText
                : month !== grid.month ? colors.muted
                : colors.text
              opacity: month !== grid.month ? 0.5 : 1
              font.family: calendarPopup.fontFamily
              font.pixelSize: 12
              horizontalAlignment: Text.AlignHCenter
              verticalAlignment: Text.AlignVCenter
            }
          }

          onClicked: (date) => grid.selectedDate = date
        }

        // Bouton "Aujourd'hui" : revient au mois courant et selectionne ce jour.
        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: 32

          Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 116
            height: 32
            radius: 999
            color: todayArea.containsMouse
              ? Qt.rgba(colors.primary.r, colors.primary.g, colors.primary.b, 0.28)
              : Qt.rgba(colors.primary.r, colors.primary.g, colors.primary.b, 0.16)
            border.width: 1
            border.color: Qt.rgba(colors.primary.r, colors.primary.g, colors.primary.b, 0.38)

            Text {
              anchors.centerIn: parent
              text: "Aujourd'hui"
              color: colors.textStrong
              font.family: calendarPopup.fontFamily
              font.pixelSize: 12
              font.bold: true
            }

            MouseArea {
              id: todayArea
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                var now = new Date()
                grid.year = now.getFullYear()
                grid.month = now.getMonth()
                grid.selectedDate = now
              }
            }
          }
        }
      }
    }
  }
}
