// Clickable icon of the idle pill.
import QtQuick

Item {
  id: g
  property string glyph: ""
  property color color: "#f5f5f7"
  property string glyphFont: "monospace"
  property int size: 14
  signal clicked()

  implicitWidth: label.implicitWidth + 4
  implicitHeight: 24
  anchors.verticalCenter: parent ? parent.verticalCenter : undefined

  Text {
    id: label
    anchors.centerIn: parent
    text: g.glyph
    color: g.color
    opacity: hover.hovered ? 1 : 0.88
    scale: tap.pressed ? 0.85 : hover.hovered ? 1.12 : 1
    font.family: g.glyphFont
    font.pixelSize: g.size
    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
  }
  HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
  TapHandler { id: tap; gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: g.clicked() }
}
