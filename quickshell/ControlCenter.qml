// Control Center-style dashboard: Connections block, Music block,
// real brightness and volume sliders, two rows of shortcuts.
// State comes from the island (shell.qml); actions go back as signals.
import QtQuick
import "I18n.js" as I18n
import Quickshell
import Quickshell.Io

Column {
  id: cc
  // state
  property var player: null
  property bool wifiOn: false
  property string wifiName: ""
  property bool btOn: false
  property string btDevice: ""
  property bool stayAwake: false
  property bool dnd: false
  property bool recording: false
  property string recElapsed: ""
  property real volume: 0
  property bool muted: false
  property bool active: false
  // style
  property color accent: "white"
  property color textColor: "white"
  property color subColor: "gray"
  property color red: "red"
  property string textFont: "sans"
  property string displayFont: "sans"
  property string glyphFont: "monospace"
  // where the cover art sits (the island draws it while it travels)
  readonly property real artX: mediaTile.x + 14
  readonly property real artY: tiles.y + 14
  readonly property real artSize: 58

  property var plugins: []          // ids in ~/.config/omarchy/plugins
  signal toggleWifi()
  signal toggleBt()
  signal toggleCaffeine()
  signal toggleDnd()
  signal openPanel(string id)
  signal run(var argv)
  signal action(string act)
  signal setVolume(real v)

  spacing: 14

  // ── Brightness (read when the dashboard opens) ────────────────────────────
  property real brightness: 1
  Process {
    id: brightRead
    command: ["bash", "-c", "brightnessctl -m 2>/dev/null | awk -F, '{gsub(\"%\",\"\",$4); print $4; exit}'"]
    stdout: StdioCollector { onStreamFinished: { const v = parseFloat(text); if (!isNaN(v)) cc.brightness = v / 100 } }
  }
  onActiveChanged: if (active) brightRead.running = true
  property real pendingBrightness: -1
  Timer {
    id: brightWrite
    interval: 60
    onTriggered: {
      if (cc.pendingBrightness < 0) return
      Quickshell.execDetached(["omarchy-brightness-display", "--no-osd", Math.max(1, Math.round(cc.pendingBrightness * 100)) + "%"])
      cc.pendingBrightness = -1
    }
  }

  // ── Top blocks ────────────────────────────────────────────────────────────
  Row {
    id: tiles
    width: parent.width
    spacing: 12

    // Connections
    Rectangle {
      id: connTile
      // Without music, connections take the full width, in a 2×2 grid.
      width: cc.player ? (parent.width - parent.spacing) * 0.48 : parent.width
      height: cc.player ? 200 : 2 * 44 + 2 + 24
      radius: 26
      color: Qt.alpha(cc.textColor, 0.07)
      Grid {
        id: connGrid
        anchors.fill: parent
        anchors.margins: 12
        columns: cc.player ? 1 : 2
        columnSpacing: 10
        rowSpacing: 2
        Repeater {
          model: [
            { glyph: cc.wifiOn ? "󰤨" : "󰤮", title: "Wi-Fi", sub: cc.wifiOn ? (cc.wifiName || I18n.t("on")) : I18n.t("off"), on: cc.wifiOn, act: "wifi", panel: "omarchy.network" },
            { glyph: cc.btOn ? "󰂯" : "󰂲", title: "Bluetooth", sub: cc.btOn ? (cc.btDevice || I18n.t("on")) : I18n.t("off"), on: cc.btOn, act: "bt", panel: "omarchy.bluetooth" },
            { glyph: "󰅶", title: I18n.t("caffeine"), sub: cc.stayAwake ? I18n.t("caffeineOn") : I18n.t("off"), on: cc.stayAwake, act: "caffeine", panel: "" },
            { glyph: "󰂛", title: I18n.t("dnd"), sub: cc.dnd ? I18n.t("active") : I18n.t("off"), on: cc.dnd, act: "dnd", panel: "" }
          ]
          Item {
            required property var modelData
            width: (connGrid.width - (connGrid.columns - 1) * connGrid.columnSpacing) / connGrid.columns
            height: 44
            Rectangle {
              id: dot
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              width: 36; height: 36; radius: 18
              color: modelData.on ? cc.accent : Qt.alpha(cc.textColor, dotHover.hovered ? 0.2 : 0.12)
              Behavior on color { ColorAnimation { duration: 140 } }
              scale: dotTap.pressed ? 0.9 : 1
              Behavior on scale { NumberAnimation { duration: 90 } }
              Text {
                anchors.centerIn: parent
                text: modelData.glyph
                color: modelData.on ? "white" : cc.textColor
                font.family: cc.glyphFont
                font.pixelSize: 15
              }
              HoverHandler { id: dotHover; cursorShape: Qt.PointingHandCursor }
              TapHandler {
                id: dotTap
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onTapped: {
                  if (modelData.act === "wifi") cc.toggleWifi()
                  else if (modelData.act === "bt") cc.toggleBt()
                  else if (modelData.act === "caffeine") cc.toggleCaffeine()
                  else cc.toggleDnd()
                }
              }
            }
            Column {
              anchors.left: dot.right
              anchors.leftMargin: 10
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              Text {
                width: parent.width
                text: modelData.title
                elide: Text.ElideRight
                color: cc.textColor
                font.family: cc.textFont
                font.pixelSize: 13
                font.weight: Font.DemiBold
              }
              Text {
                width: parent.width
                text: modelData.sub
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: cc.subColor
                font.family: cc.textFont
                font.pixelSize: 11
              }
            }
            // Click on the name: opens the full panel
            HoverHandler { enabled: modelData.panel !== ""; cursorShape: Qt.PointingHandCursor }
            TapHandler {
              enabled: modelData.panel !== ""
              gesturePolicy: TapHandler.ReleaseWithinBounds
              onTapped: cc.openPanel(modelData.panel)
            }
          }
        }
      }
    }

    // Music
    Rectangle {
      id: mediaTile
      visible: !!cc.player
      width: parent.width - connTile.width - parent.spacing
      height: 200
      radius: 26
      color: Qt.alpha(cc.textColor, 0.07)
      readonly property real length: cc.player && cc.player.lengthSupported ? cc.player.length : 0
      readonly property real position: cc.player && cc.player.positionSupported ? cc.player.position : 0

      // Cover art slot (the island draws the travelling one on top of it)
      Rectangle {
        x: 14; y: 14
        width: cc.artSize; height: cc.artSize; radius: 14
        visible: !cc.player
        color: Qt.alpha(cc.textColor, 0.08)
        Text {
          anchors.centerIn: parent
          text: "󰝚"
          color: cc.accent
          font.family: cc.glyphFont
          font.pixelSize: 24
        }
      }
      Column {
        x: 14
        y: 14 + cc.artSize + 10
        width: parent.width - 28
        spacing: 1
        Text {
          width: parent.width
          text: cc.player ? (cc.player.trackTitle || cc.player.identity || "") : I18n.t("nothingPlaying")
          textFormat: Text.PlainText
          elide: Text.ElideRight
          color: cc.textColor
          font.family: cc.textFont
          font.pixelSize: 13
          font.weight: Font.DemiBold
        }
        Text {
          width: parent.width
          visible: !!cc.player
          text: cc.player ? (cc.player.trackArtist || cc.player.identity || "") : ""
          textFormat: Text.PlainText
          elide: Text.ElideRight
          color: cc.subColor
          font.family: cc.textFont
          font.pixelSize: 11
        }
      }
      Rectangle {
        visible: mediaTile.length > 0
        x: 14
        y: parent.height - 62
        width: parent.width - 28
        height: 4; radius: 2
        color: Qt.alpha(cc.textColor, 0.16)
        Rectangle {
          height: parent.height; radius: 2
          width: parent.width * Math.max(0, Math.min(1, mediaTile.length > 0 ? mediaTile.position / mediaTile.length : 0))
          color: cc.textColor
          Behavior on width { NumberAnimation { duration: 900; easing.type: Easing.Linear } }
        }
      }
      Row {
        visible: !!cc.player
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        spacing: 14
        Repeater {
          model: [
            { glyph: "󰒮", act: "prev", size: 18 },
            { glyph: cc.player && cc.player.isPlaying ? "󰏤" : "󰐊", act: "play", size: 24 },
            { glyph: "󰒭", act: "next", size: 18 }
          ]
          Rectangle {
            required property var modelData
            width: 40; height: 40; radius: 20
            color: Qt.alpha(cc.textColor, mHover.hovered ? 0.14 : 0)
            scale: mTap.pressed ? 0.88 : 1
            Behavior on scale { NumberAnimation { duration: 90 } }
            Text {
              anchors.centerIn: parent
              text: modelData.glyph
              color: cc.textColor
              font.family: cc.glyphFont
              font.pixelSize: modelData.size
            }
            HoverHandler { id: mHover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
              id: mTap
              gesturePolicy: TapHandler.ReleaseWithinBounds
              onTapped: {
                const p = cc.player
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

  // Nothing playing: a thin pill instead of the block.
  Rectangle {
    visible: !cc.player
    width: parent.width
    height: 46
    radius: 23
    color: Qt.alpha(cc.textColor, 0.07)
    Row {
      anchors.centerIn: parent
      spacing: 8
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "󰝚"
        color: cc.accent
        font.family: cc.glyphFont
        font.pixelSize: 15
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: I18n.t("nothingPlaying")
        color: cc.subColor
        font.family: cc.textFont
        font.pixelSize: 13
      }
    }
  }

  // ── Brightness and volume sliders ─────────────────────────────────────────
  component BigSlider: Rectangle {
    id: sl
    property real value: 0
    property string glyph: ""
    signal moved(real v)
    signal iconClicked()
    width: parent ? parent.width : 300
    height: 44
    radius: 22
    color: Qt.alpha(cc.textColor, 0.09)
    clip: true
    Rectangle {
      width: Math.max(sl.height, sl.width * Math.max(0, Math.min(1, sl.value)))
      height: parent.height
      radius: parent.radius
      color: Qt.alpha(cc.textColor, drag.active || area.containsMouse ? 0.92 : 0.85)
      Behavior on width { enabled: !area.pressed; NumberAnimation { duration: 120 } }
    }
    MouseArea {
      id: area
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      property bool dragging: false
      function setFrom(x) { sl.moved(Math.max(0, Math.min(1, x / sl.width))) }
      onPressed: function(m) { if (m.x > 46) setFrom(m.x) }
      onPositionChanged: function(m) { if (pressed && m.x > 0) setFrom(m.x) }
      onClicked: function(m) { if (m.x <= 46) sl.iconClicked() }
      onWheel: function(w) { sl.moved(Math.max(0, Math.min(1, sl.value + (w.angleDelta.y > 0 ? 0.05 : -0.05)))) }
    }
    DragHandler { id: drag; target: null; enabled: false }
    Text {
      anchors.left: parent.left
      anchors.leftMargin: 15
      anchors.verticalCenter: parent.verticalCenter
      text: sl.glyph
      color: sl.value > 0.08 ? "black" : cc.textColor
      opacity: 0.75
      font.family: cc.glyphFont
      font.pixelSize: 16
    }
  }

  BigSlider {
    value: cc.brightness
    glyph: "󰃠"
    onMoved: function(v) { cc.brightness = v; cc.pendingBrightness = v; if (!brightWrite.running) brightWrite.start() }
    onIconClicked: cc.openPanel("omarchy.monitor")
  }
  BigSlider {
    value: cc.muted ? 0 : cc.volume
    glyph: cc.muted || cc.volume < 0.01 ? "󰖁" : cc.volume < 0.5 ? "󰖀" : "󰕾"
    onMoved: function(v) { cc.setVolume(v) }
    onIconClicked: cc.openPanel("omarchy.audio")
  }

  // ── Shortcuts ─────────────────────────────────────────────────────────────
  Grid {
    anchors.horizontalCenter: parent.horizontalCenter
    columns: 7
    columnSpacing: 10
    rowSpacing: 8
    Repeater {
      // Tiles of optional third-party plugins show only when they are installed.
      model: [
        { glyph: "󰹑", label: I18n.t("screenshot"), act: "shot" },
        { glyph: "󰻂", label: cc.recording ? cc.recElapsed : I18n.t("record"), act: "record", on: cc.recording, tint: cc.red },
        { glyph: "󰖐", label: I18n.t("weather"), panel: "omarchy.weather" },
        { glyph: "󰃭", label: I18n.t("calendar"), panel: "omarchy.clock" },
        { glyph: "󰂚", label: I18n.t("notifications"), act: "center" },
        { glyph: "󰇧", label: I18n.t("timezones"), panel: "omarchy.elsewhen" },
        { glyph: "\u{F08C7}", label: I18n.t("menu"), panel: "omarchy.menu" },
        { glyph: "\u{F035B}", label: I18n.t("system"), panel: "crmne.omastats", needs: "crmne.omastats" },
        { glyph: "\u{F02A4}", label: "GitHub", panel: "luca.github", needs: "luca.github" },
        { glyph: "󰚩", label: I18n.t("agents"), panel: "omarchy.agents" },
        { glyph: "󰶘", label: "Omadrop", panel: "lucas.omadrop", needs: "lucas.omadrop" },
        { glyph: "󰁹", label: I18n.t("battery"), panel: "omarchy.power" },
        { glyph: "󰚰", label: I18n.t("update"), act: "update" },
        { glyph: "󰌾", label: I18n.t("lock"), act: "lock" }
      ].filter(t => !t.needs || cc.plugins.includes(t.needs))
      Item {
        required property var modelData
        width: 54; height: 62
        Rectangle {
          id: sc
          anchors.horizontalCenter: parent.horizontalCenter
          width: 44; height: 44; radius: 22
          color: modelData.on ? (modelData.tint || cc.accent) : Qt.alpha(cc.textColor, scHover.hovered ? 0.18 : 0.1)
          Behavior on color { ColorAnimation { duration: 140 } }
          scale: scTap.pressed ? 0.9 : 1
          Behavior on scale { NumberAnimation { duration: 90 } }
          Text {
            anchors.centerIn: parent
            text: modelData.glyph
            color: modelData.on ? "white" : cc.textColor
            font.family: cc.glyphFont
            font.pixelSize: 17
          }
          HoverHandler { id: scHover; cursorShape: Qt.PointingHandCursor }
          TapHandler {
            id: scTap
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: modelData.panel ? cc.openPanel(modelData.panel) : cc.action(modelData.act)
          }
        }
        Text {
          anchors.top: sc.bottom
          anchors.topMargin: 4
          anchors.horizontalCenter: parent.horizontalCenter
          width: parent.width + 8
          horizontalAlignment: Text.AlignHCenter
          text: modelData.label
          elide: Text.ElideRight
          color: Qt.alpha(cc.textColor, 0.7)
          font.family: cc.textFont
          font.pixelSize: 10
          font.weight: Font.Medium
        }
      }
    }
  }
}
