// Island expanded on music: cover art, title, artist, progress and
// controls. Works with any MPRIS player (Spotify, browsers, mpv…).
import QtQuick
import QtQuick.Effects

Item {
  id: view
  property var player: null
  property color accent: "white"
  property color textColor: "white"
  property color subColor: "gray"
  property string textFont: "sans"
  property string glyphFont: "monospace"
  // The cover art is drawn by the island while it travels from the pill to here.
  property bool artHidden: false
  readonly property bool artReady: art.status === Image.Ready

  readonly property real length: player && player.lengthSupported ? player.length : 0
  readonly property real position: player && player.positionSupported ? player.position : 0

  function fmt(s) {
    if (!isFinite(s) || s < 0) s = 0
    const m = Math.floor(s / 60)
    const r = Math.floor(s % 60)
    return m + ":" + (r < 10 ? "0" : "") + r
  }

  // Cover art
  Item {
    id: artBox
    width: 84; height: 84
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter

    Rectangle {
      anchors.fill: parent
      radius: 14
      color: Qt.alpha(view.textColor, 0.08)
      visible: art.status !== Image.Ready && !view.artHidden
      Text {
        anchors.centerIn: parent
        text: "󰝚"
        color: view.accent
        font.family: view.glyphFont
        font.pixelSize: 30
      }
    }
    Image {
      id: art
      anchors.fill: parent
      source: view.player ? (view.player.trackArtUrl || "") : ""
      sourceSize: Qt.size(168, 168)
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      visible: false
    }
    Rectangle { id: artMask; anchors.fill: parent; radius: 14; visible: false; layer.enabled: true }
    MultiEffect {
      anchors.fill: parent
      source: art
      visible: art.status === Image.Ready && !view.artHidden
      maskEnabled: true
      maskSource: artMask
    }
  }

  Column {
    anchors.left: artBox.right
    anchors.leftMargin: 14
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    spacing: 4

    Item {
      width: parent.width
      height: titleText.implicitHeight
      Text {
        id: titleText
        anchors.left: parent.left
        anchors.right: eqBig.left
        anchors.rightMargin: 10
        text: view.player ? (view.player.trackTitle || view.player.identity || "") : ""
        color: view.textColor
        elide: Text.ElideRight
        font.family: view.textFont
        font.pixelSize: 15
        font.weight: Font.DemiBold
      }
      Equalizer {
        id: eqBig
        anchors.right: parent.right
        anchors.verticalCenter: titleText.verticalCenter
        playing: !!view.player && view.player.isPlaying
        barColor: view.accent
      }
    }
    Text {
      width: parent.width
      text: view.player ? (view.player.trackArtist || view.player.identity || "") : ""
      color: view.subColor
      elide: Text.ElideRight
      font.family: view.textFont
      font.pixelSize: 12
    }

    // Progress
    Item {
      width: parent.width
      height: 16
      visible: view.length > 0
      Text {
        id: posText
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: view.fmt(view.position)
        color: view.subColor
        font.family: view.textFont
        font.pixelSize: 10
        font.features: { "tnum": 1 }
      }
      Rectangle {
        id: track
        anchors.left: posText.right
        anchors.right: lenText.left
        anchors.margins: 8
        anchors.verticalCenter: parent.verticalCenter
        height: 4; radius: 2
        color: Qt.alpha(view.textColor, 0.16)
        Rectangle {
          height: parent.height; radius: 2
          width: parent.width * Math.max(0, Math.min(1, view.length > 0 ? view.position / view.length : 0))
          color: view.textColor
          Behavior on width { NumberAnimation { duration: 900; easing.type: Easing.Linear } }
        }
        TapHandler {
          enabled: !!view.player && view.player.canSeek
          onTapped: function(ev) {
            view.player.position = view.length * Math.max(0, Math.min(1, ev.position.x / track.width))
          }
        }
      }
      Text {
        id: lenText
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: "-" + view.fmt(view.length - view.position)
        color: view.subColor
        font.family: view.textFont
        font.pixelSize: 10
        font.features: { "tnum": 1 }
      }
    }

    // Controls
    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 26
      Repeater {
        model: [
          { glyph: "󰒮", act: "prev", size: 18 },
          { glyph: view.player && view.player.isPlaying ? "󰏤" : "󰐊", act: "play", size: 24 },
          { glyph: "󰒭", act: "next", size: 18 }
        ]
        Text {
          required property var modelData
          anchors.verticalCenter: parent.verticalCenter
          text: modelData.glyph
          color: ctlHover.hovered ? view.accent : view.textColor
          font.family: view.glyphFont
          font.pixelSize: modelData.size
          scale: ctlTap.pressed ? 0.85 : 1
          Behavior on scale { NumberAnimation { duration: 90 } }
          HoverHandler { id: ctlHover; cursorShape: Qt.PointingHandCursor }
          TapHandler {
            id: ctlTap
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
}
