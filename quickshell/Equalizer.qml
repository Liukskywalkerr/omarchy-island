// Four bars that dance while music plays and flatten when paused.
import QtQuick

Row {
  id: eq
  property bool playing: false
  property color barColor: "white"
  spacing: 2
  height: 12

  Repeater {
    model: 4
    Rectangle {
      id: bar
      required property int index
      width: 2.5
      radius: 1.25
      anchors.bottom: parent.bottom
      color: eq.barColor
      height: 3

      SequentialAnimation on height {
        running: eq.playing
        loops: Animation.Infinite
        NumberAnimation { to: [9, 12, 7, 10][bar.index]; duration: [380, 300, 420, 340][bar.index]; easing.type: Easing.InOutSine }
        NumberAnimation { to: [4, 5, 3, 6][bar.index];   duration: [340, 280, 360, 300][bar.index]; easing.type: Easing.InOutSine }
        NumberAnimation { to: [11, 8, 12, 7][bar.index]; duration: [300, 360, 320, 400][bar.index]; easing.type: Easing.InOutSine }
        NumberAnimation { to: [5, 3, 6, 4][bar.index];   duration: [360, 320, 300, 360][bar.index]; easing.type: Easing.InOutSine }
        onRunningChanged: if (!running) bar.height = 3
      }
      Behavior on height { enabled: !eq.playing; NumberAnimation { duration: 200 } }
    }
  }
}
