// Round dashboard button: icon in a circle with the label below.
import QtQuick

Item {
  id: btn
  property string glyph: ""
  property string label: ""
  property bool active: false
  property color accent: "white"
  property color textColor: "white"
  property color bgColor: "black"
  property string textFont: "sans"
  property string glyphFont: "monospace"
  signal clicked()

  width: 54
  height: 62

  Rectangle {
    id: circle
    anchors.horizontalCenter: parent.horizontalCenter
    width: 44; height: 44; radius: 22
    color: btn.active ? btn.accent
         : hover.hovered ? Qt.alpha(btn.textColor, 0.18) : Qt.alpha(btn.textColor, 0.10)
    scale: tap.pressed ? 0.9 : 1
    Behavior on color { ColorAnimation { duration: 140 } }
    Behavior on scale { NumberAnimation { duration: 90 } }
    Text {
      anchors.centerIn: parent
      text: btn.glyph
      color: btn.active ? btn.bgColor : btn.textColor
      font.family: btn.glyphFont
      font.pixelSize: 18
    }
  }
  Text {
    anchors.top: circle.bottom
    anchors.topMargin: 5
    anchors.horizontalCenter: parent.horizontalCenter
    width: parent.width + 8
    horizontalAlignment: Text.AlignHCenter
    text: btn.label
    textFormat: Text.PlainText
    elide: Text.ElideRight
    color: Qt.alpha(btn.textColor, 0.7)
    font.family: btn.textFont
    font.pixelSize: 10
    font.weight: Font.Medium
  }

  HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
  TapHandler { id: tap; gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: btn.clicked() }
}
