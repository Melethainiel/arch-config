import QtQuick

Rectangle {
  id: bubble

  required property var colors
  property string fontFamily: "JetBrainsMono Nerd Font"
  property alias label: bubbleText.text
  property color labelColor: colors.text
  property int horizontalPadding: 12
  property int minWidth: 0
  property int textPixelSize: 13
  property bool bold: false

  implicitWidth: Math.max(minWidth, bubbleText.implicitWidth + horizontalPadding * 2)
  implicitHeight: 34
  radius: 999
  color: colors.bg

  Text {
    id: bubbleText
    anchors.centerIn: parent
    color: bubble.labelColor
    font.family: bubble.fontFamily
    font.pixelSize: bubble.textPixelSize
    font.bold: bubble.bold
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
  }
}
