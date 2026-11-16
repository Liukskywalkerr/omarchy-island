// Drawn battery (not a font glyph): rounded body, terminal on the
// right, fill proportional to the level; a bolt while charging.
// Optically centered: the terminal doesn't shift the body off center.
import QtQuick
import QtQuick.Shapes

Item {
  id: icon
  property real level: 0.5          // 0..1
  property bool charging: false
  property color tint: "white"      // fill color
  property color outline: "white"
  width: 22; height: 12

  Rectangle {
    id: body
    width: 19; height: 11
    anchors.verticalCenter: parent.verticalCenter
    x: 0
    radius: 3.5
    color: "transparent"
    border.width: 1.4
    border.color: Qt.alpha(icon.outline, 0.55)
    Rectangle {
      x: 2.2; y: 2.2
      height: parent.height - 4.4
      width: Math.max(2, (parent.width - 4.4) * Math.max(0, Math.min(1, icon.level)))
      radius: 1.6
      color: icon.tint
    }
  }
  Rectangle {
    anchors.left: body.right
    anchors.leftMargin: 1
    anchors.verticalCenter: body.verticalCenter
    width: 1.8; height: 4.5
    radius: 1
    color: Qt.alpha(icon.outline, 0.55)
  }
  // Bolt over the battery while charging
  Shape {
    visible: icon.charging
    anchors.centerIn: body
    width: 8; height: 11
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      fillColor: "white"
      strokeColor: Qt.rgba(0, 0, 0, 0.35)
      strokeWidth: 0.8
      startX: 4.8; startY: 0
      PathLine { x: 0.6; y: 6.2 }
      PathLine { x: 3.6; y: 6.2 }
      PathLine { x: 2.8; y: 11 }
      PathLine { x: 7.4; y: 4.6 }
      PathLine { x: 4.4; y: 4.6 }
      PathLine { x: 4.8; y: 0 }
    }
  }
}
