import QtQuick
import qs.Commons
import qs.Commons as Commons

// omarchy-island: light separator (same API as qs.Ui/PanelSeparator).
Rectangle {
  property color foreground: Commons.Color.foreground
  property real strength: 0.07
  width: parent ? parent.width : implicitWidth
  implicitWidth: 100
  implicitHeight: 1
  height: 1
  color: Qt.alpha(foreground, strength)
}
