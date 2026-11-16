// Compact pill player, shown when hovering the island while something
// is playing. The cover art on the left is drawn by the island (heroArt);
// this leaves room for it: title, artist, progress and controls.
import QtQuick

Item {
  id: view
  property var player: null
  property color accent: "white"
  property color textColor: "white"
  property color subColor: "gray"
  property string textFont: "sans"
  property string glyphFont: "monospace"
  property real artSlot: 60            // diameter of the cover art circle

  readonly property real length: player && player.lengthSupported ? player.length : 0
  readonly property real position: player && player.positionSupported ? player.position : 0

  Column {
    anchors.left: parent.left
    anchors.leftMargin: view.artSlot + 14
    anchors.right: controls.left
    anchors.rightMargin: 14
    anchors.verticalCenter: parent.verticalCenter
    spacing: 3
    Text {
      width: parent.width
      text: view.player ? (view.player.trackTitle || view.player.identity || "") : ""
      textFormat: Text.PlainText
      elide: Text.ElideRight
      color: view.textColor
      font.family: view.textFont
      font.pixelSize: 13
      font.weight: Font.DemiBold
    }
    Text {
      width: parent.width
      text: view.player ? (view.player.trackArtist || view.player.identity || "") : ""
      textFormat: Text.PlainText
      elide: Text.ElideRight
      color: view.subColor
      font.family: view.textFont
      font.pixelSize: 11
    }
    Rectangle {
      visible: view.length > 0
      width: parent.width
      height: 4
      radius: 2
      color: Qt.alpha(view.textColor, 0.16)
      Rectangle {
        height: parent.height
        radius: 2
        width: parent.width * Math.max(0, Math.min(1, view.length > 0 ? view.position / view.length : 0))
        color: view.textColor
        Behavior on width { NumberAnimation { duration: 900; easing.type: Easing.Linear } }
      }
    }
  }

  Row {
    id: controls
    anchors.right: parent.right
    anchors.rightMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    spacing: 4
    Repeater {
      model: [
        { glyph: "󰒮", act: "prev", size: 17 },
        { glyph: view.player && view.player.isPlaying ? "󰏤" : "󰐊", act: "play", size: 22 },
        { glyph: "󰒭", act: "next", size: 17 }
      ]
      Rectangle {
        required property var modelData
        width: 38; height: 38; radius: 19
        color: Qt.alpha(view.textColor, ctlHover.hovered ? 0.14 : 0)
        Behavior on color { ColorAnimation { duration: 120 } }
        scale: ctlTap.pressed ? 0.88 : 1
        Behavior on scale { NumberAnimation { duration: 90 } }
        Text {
          anchors.centerIn: parent
          text: modelData.glyph
          color: view.textColor
          font.family: view.glyphFont
          font.pixelSize: modelData.size
        }
        HoverHandler { id: ctlHover; cursorShape: Qt.PointingHandCursor }
        TapHandler {
          id: ctlTap
          gesturePolicy: TapHandler.ReleaseWithinBounds
          onTapped: {
            const p = view.player
            if (!p) return
            if (modelData.act === "prev" && p.canGoPrevious) p.previous()
            else if (modelData.act === "next" && p.canGoNext) p.next()
            else if (modelData.act === "play" && p.canTogglePlaying) p.togglePlaying()
          }
        }
      }
    }
  }
}
