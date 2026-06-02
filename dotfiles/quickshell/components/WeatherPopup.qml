import QtQuick
import Quickshell

Rectangle {
  id: weatherPopup

  required property var colors
  required property var parentWindow
  property string fontFamily: "JetBrainsMono Nerd Font"
  property var forecast: ({})
  property bool open: false

  readonly property var current: forecast.current || ({})
  readonly property var daily: forecast.daily || ({})
  readonly property var times: daily.time || []
  readonly property var maxTemps: daily.temperature_2m_max || []
  readonly property var minTemps: daily.temperature_2m_min || []
  readonly property var precipitations: daily.precipitation_probability_max || []
  readonly property var codes: daily.weather_code || []
  readonly property string currentLabel: Number.isFinite(Number(current.temperature_2m)) ? iconForCode(Number(current.weather_code)) + " " + Math.round(Number(current.temperature_2m)) + "°" : "meteo"

  function iconForCode(code) {
    if (code === 0)
      return "󰖙"
    if (code === 1 || code === 2)
      return "󰖕"
    if (code === 3)
      return "󰖐"
    if (code === 45 || code === 48)
      return "󰖑"
    if (code >= 51 && code <= 67)
      return "󰖗"
    if (code >= 71 && code <= 77)
      return "󰖘"
    if (code >= 80 && code <= 82)
      return "󰖖"
    if (code >= 95)
      return "󰖓"
    return "󰖐"
  }

  function dayLabel(value) {
    const date = new Date(value)

    if (Number.isNaN(date.getTime()))
      return "--"

    return date.toLocaleDateString(Qt.locale("fr_FR"), "ddd")
  }

  function tempLabel(index) {
    const maxTemp = Number(maxTemps[index])
    const minTemp = Number(minTemps[index])

    if (!Number.isFinite(maxTemp) || !Number.isFinite(minTemp))
      return "--"

    return Math.round(maxTemp) + "° " + Math.round(minTemp) + "°"
  }

  function rainLabel(index) {
    const rain = Number(precipitations[index])

    return Number.isFinite(rain) ? rain + "%" : "--"
  }

  implicitWidth: Math.max(84, currentText.implicitWidth + 24)
  implicitHeight: 34
  color: "transparent"

  onOpenChanged: forecastWindow.visible = open

  Rectangle {
    id: weatherBubble
    anchors.horizontalCenter: parent.horizontalCenter
    y: 0
    width: weatherPopup.implicitWidth
    height: 34
    radius: 999
    color: weatherPopup.open ? colors.surface : colors.bg
    border.width: weatherPopup.open ? 1 : 0
    border.color: Qt.rgba(colors.secondary.r, colors.secondary.g, colors.secondary.b, 0.45)

    Behavior on color { ColorAnimation { duration: 160 } }
  }

  Text {
    id: currentText
    anchors.centerIn: weatherBubble
    text: weatherPopup.currentLabel
    color: colors.secondary
    font.family: weatherPopup.fontFamily
    font.pixelSize: 13
    verticalAlignment: Text.AlignVCenter
  }

  MouseArea {
    anchors.fill: weatherBubble
    cursorShape: Qt.PointingHandCursor
    onClicked: weatherPopup.open = !weatherPopup.open
  }

  PopupWindow {
    id: forecastWindow

    implicitWidth: 494
    implicitHeight: 124
    color: "transparent"
    grabFocus: true

    anchor.window: weatherPopup.parentWindow
    anchor.rect.x: Math.round(weatherBubble.mapToItem(null, 0, 0).x + weatherBubble.width / 2 - implicitWidth / 2 + 112)
    anchor.rect.y: Math.round(weatherBubble.mapToItem(null, 0, 0).y + 42)

    onVisibleChanged: {
      if (!visible)
        weatherPopup.open = false
    }

    Rectangle {
      id: forecastPanel
      anchors.fill: parent
      radius: 18
      color: colors.surface
      border.width: 1
      border.color: Qt.rgba(colors.secondary.r, colors.secondary.g, colors.secondary.b, 0.34)
      clip: true

      Row {
        anchors.centerIn: parent
        spacing: 8

        Repeater {
          model: Math.min(7, weatherPopup.times.length)

          Rectangle {
            width: 62
            height: 102
            radius: 16
            color: index === 0 ? Qt.rgba(weatherPopup.colors.secondary.r, weatherPopup.colors.secondary.g, weatherPopup.colors.secondary.b, 0.18) : weatherPopup.colors.surfaceHover
            border.width: index === 0 ? 1 : 0
            border.color: Qt.rgba(weatherPopup.colors.secondary.r, weatherPopup.colors.secondary.g, weatherPopup.colors.secondary.b, 0.38)

            Column {
              anchors.centerIn: parent
              spacing: 6

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: index === 0 ? "auj" : weatherPopup.dayLabel(weatherPopup.times[index])
                color: weatherPopup.colors.textStrong
                font.family: weatherPopup.fontFamily
                font.pixelSize: 12
                font.bold: index === 0
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: weatherPopup.iconForCode(Number(weatherPopup.codes[index]))
                color: weatherPopup.colors.secondary
                font.family: weatherPopup.fontFamily
                font.pixelSize: 22
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: weatherPopup.tempLabel(index)
                color: weatherPopup.colors.textStrong
                font.family: weatherPopup.fontFamily
                font.pixelSize: 12
                font.bold: true
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰖗 " + weatherPopup.rainLabel(index)
                color: weatherPopup.colors.textStrong
                font.family: weatherPopup.fontFamily
                font.pixelSize: 11
              }
            }
          }
        }
      }

      Text {
        anchors.centerIn: parent
        visible: weatherPopup.times.length === 0
        text: "meteo indisponible"
        color: colors.muted
        font.family: weatherPopup.fontFamily
        font.pixelSize: 12
      }
    }
  }
}
