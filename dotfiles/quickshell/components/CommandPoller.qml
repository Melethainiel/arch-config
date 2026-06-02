import QtQuick
import Quickshell.Io

Item {
  id: poller

  property var command: []
  property int interval: 1000
  property string text: ""

  visible: false

  function refresh() {
    if (!process.running)
      process.exec(poller.command)
  }

  Component.onCompleted: refresh()

  Timer {
    interval: poller.interval
    repeat: true
    running: true
    triggeredOnStart: false
    onTriggered: poller.refresh()
  }

  Process {
    id: process
    command: poller.command
    stdout: StdioCollector {
      onStreamFinished: poller.text = text.trim()
    }
  }
}
