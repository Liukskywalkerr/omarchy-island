// Notification center inside the island. The history is Omarchy's own
// (~/.local/state/omarchy/notifications/history.json, last 100): it is read
// from here and modified through the notifications clone's IPC.
import QtQuick
import "I18n.js" as I18n
import Quickshell
import Quickshell.Io
import "Brand.js" as Brand

Item {
  id: view
  property color accent: "white"
  property color textColor: "white"
  property color subColor: "gray"
  property color red: "red"
  property string textFont: "sans"
  property string displayFont: "sans"
  property string glyphFont: "monospace"
  property bool dnd: false
  property bool active: false
  readonly property int maxListHeight: 520
  implicitHeight: header.height + 14 + (entries.length ? Math.min(list.contentHeight, maxListHeight) : 70)

  signal toggleDnd()

  // ── History ───────────────────────────────────────────────────────────────
  property var entries: []
  FileView {
    id: historyFile
    path: Quickshell.env("HOME") + "/.local/state/omarchy/notifications/history.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try {
        const list = JSON.parse(text() || "[]")
        view.entries = Array.isArray(list) ? list.filter(e => e && e.key && (e.summary || e.body)) : []
      } catch (e) {}
      view.rebuild()
    }
  }
  onActiveChanged: if (active) { historyFile.reload(); armed = false }

  // Tick for "2 min ago" while open.
  property double now: Date.now()
  Timer { running: view.active; repeat: true; interval: 30000; onTriggered: view.now = Date.now() }

  function dayOf(ts) {
    const when = new Date(ts * 1000)
    const now = new Date()
    const midnight = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime()
    const it = Qt.locale()
    if (when.getTime() >= midnight) return I18n.t("today")
    if (when.getTime() >= midnight - 86400000) return I18n.t("yesterday")
    const s = when.toLocaleDateString(it, when.getTime() >= midnight - 6 * 86400000 ? "dddd" : "d MMMM")
    return s.charAt(0).toUpperCase() + s.slice(1)
  }
  function ago(ts) {
    const age = Math.max(0, view.now / 1000 - ts)
    if (age < 60) return "ora"
    if (age < 3600) return I18n.t("minAgo", Math.round(age / 60))
    return Qt.formatTime(new Date(ts * 1000), "HH:mm")
  }
  function iconFor(name) {
    if (!name) return ""
    if (name.startsWith("/")) return "file://" + name
    if (name.startsWith("file://") || name.startsWith("image://")) return name
    return Quickshell.iconPath(name, true)
  }
  function clean(t) { return String(t || "").replace(/<[^>]*>/g, " ").replace(/\s+/g, " ").trim() }

  ListModel { id: rows }
  function rebuild() {
    rows.clear()
    for (const raw of view.entries) {
      const e = Brand.normalize(raw, view.webappFor, view.iconOk)
      rows.append({ key: String(e.key), app: String(e.app || ""), icon: String(e.appIcon || e.image || ""),
                    glyph: String(e.glyph || ""), summary: view.clean(e.summary), body: view.clean(e.body),
                    ts: Number(e.ts) || 0, day: view.dayOf(Number(e.ts) || 0) })
    }
  }
  function webappFor(domain) {
    for (const d of DesktopEntries.applications.values) {
      if (String(d.execString || "").indexOf("://" + domain) >= 0) return { name: d.name, icon: d.icon }
    }
    return null
  }
  function iconOk(name) { return Quickshell.iconPath(name, true) !== "" }

  function remove(key) {
    view.entries = view.entries.filter(e => e.key !== key)
    view.rebuild()
    Quickshell.execDetached(["omarchy-shell", "notifications", "islandHistoryRemove", key])
  }
  property bool armed: false
  Timer { id: disarm; interval: 4000; onTriggered: view.armed = false }
  function clearAll() {
    if (!armed) { armed = true; disarm.restart(); return }
    armed = false
    view.entries = []
    view.rebuild()
    Quickshell.execDetached(["omarchy-shell", "notifications", "islandHistoryClear"])
  }
  function open(entry) {
    if (entry) Quickshell.execDetached(["omarchy-hyprland-focus-app", entry])
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Item {
    id: header
    width: parent.width
    height: 40
    Text {
      anchors.left: parent.left
      anchors.leftMargin: 4
      anchors.verticalCenter: parent.verticalCenter
      text: I18n.t("notifications")
      color: view.textColor
      font.family: view.displayFont
      font.pixelSize: 22
      font.weight: Font.Bold
    }
    Row {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: 8
      Rectangle {
        width: 34; height: 34; radius: 17
        color: view.dnd ? view.accent : Qt.alpha(view.textColor, dndHover.hovered ? 0.18 : 0.1)
        Text {
          anchors.centerIn: parent
          text: view.dnd ? "󰂛" : "󰂚"
          color: view.dnd ? "black" : view.textColor
          font.family: view.glyphFont
          font.pixelSize: 15
        }
        HoverHandler { id: dndHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: view.toggleDnd() }
      }
      Rectangle {
        visible: view.entries.length > 0
        width: clearLabel.implicitWidth + 28; height: 34; radius: 17
        color: view.armed ? view.red : Qt.alpha(view.textColor, clearHover.hovered ? 0.18 : 0.1)
        Behavior on color { ColorAnimation { duration: 150 } }
        Text {
          id: clearLabel
          anchors.centerIn: parent
          text: view.armed ? I18n.t("sure") : I18n.t("clearAll")
          color: view.armed ? "white" : view.textColor
          font.family: view.textFont
          font.pixelSize: 13
          font.weight: Font.DemiBold
        }
        HoverHandler { id: clearHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: view.clearAll() }
      }
    }
  }

  // ── Empty ─────────────────────────────────────────────────────────────────
  Text {
    visible: view.entries.length === 0
    anchors.top: header.bottom
    anchors.topMargin: 22
    anchors.horizontalCenter: parent.horizontalCenter
    text: I18n.t("noNotifications")
    color: view.subColor
    font.family: view.textFont
    font.pixelSize: 14
  }

  // ── List ──────────────────────────────────────────────────────────────────
  ListView {
    id: list
    anchors.top: header.bottom
    anchors.topMargin: 14
    width: parent.width
    height: Math.min(contentHeight, view.maxListHeight)
    visible: view.entries.length > 0
    clip: true
    spacing: 8
    boundsBehavior: Flickable.StopAtBounds
    model: rows
    section.property: "day"
    section.delegate: Item {
      required property string section
      width: list.width
      height: 28
      Text {
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        text: parent.section
        color: view.subColor
        font.family: view.textFont
        font.pixelSize: 13
        font.weight: Font.DemiBold
      }
    }

    delegate: Rectangle {
      id: card
      required property string key
      required property string app
      required property string icon
      required property string glyph
      required property string summary
      required property string body
      required property real ts
      width: list.width
      height: Math.max(64, texts.implicitHeight + 24)
      radius: 22
      color: Qt.alpha(view.textColor, cardHover.hovered ? 0.12 : 0.07)
      Behavior on color { ColorAnimation { duration: 100 } }

      HoverHandler { id: cardHover }
      TapHandler { onTapped: view.open(card.app) }

      Rectangle {
        id: avatar
        x: 12; y: 12
        width: 40; height: 40; radius: 20
        color: Qt.alpha(view.textColor, 0.08)
        Image {
          id: avatarImg
          anchors.fill: parent
          anchors.margins: 7
          source: view.iconFor(card.icon)
          sourceSize: Qt.size(64, 64)
          fillMode: Image.PreserveAspectFit
          visible: status === Image.Ready
        }
        Text {
          anchors.centerIn: parent
          visible: avatarImg.status !== Image.Ready
          text: card.glyph || (card.app ? card.app.charAt(0).toUpperCase() : "󰂚")
          color: view.accent
          font.family: card.glyph ? view.glyphFont : view.textFont
          font.pixelSize: 17
          font.weight: Font.Bold
        }
      }

      Column {
        id: texts
        anchors.left: avatar.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 16
        y: 12
        spacing: 2
        Item {
          width: parent.width
          height: appLabel.implicitHeight
          Text {
            id: appLabel
            width: parent.width - 60
            text: card.app
            textFormat: Text.PlainText
            elide: Text.ElideRight
            color: view.subColor
            font.family: view.textFont
            font.pixelSize: 11
          }
          Text {
            anchors.right: parent.right
            visible: !cardHover.hovered
            text: view.ago(card.ts)
            color: view.subColor
            font.family: view.textFont
            font.pixelSize: 11
          }
          Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: -4
            anchors.verticalCenter: parent.verticalCenter
            visible: cardHover.hovered
            width: 22; height: 22; radius: 11
            color: Qt.alpha(view.textColor, xHover.hovered ? 0.25 : 0.14)
            Text {
              anchors.centerIn: parent
              text: "󰅖"
              color: view.textColor
              font.family: view.glyphFont
              font.pixelSize: 11
            }
            HoverHandler { id: xHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: view.remove(card.key) }
          }
        }
        Text {
          width: parent.width
          visible: card.summary !== ""
          text: card.summary
          textFormat: Text.PlainText
          elide: Text.ElideRight
          color: view.textColor
          font.family: view.textFont
          font.pixelSize: 14
          font.weight: Font.DemiBold
        }
        Text {
          width: parent.width
          visible: card.body !== ""
          text: card.body
          textFormat: Text.PlainText
          wrapMode: Text.Wrap
          maximumLineCount: 2
          elide: Text.ElideRight
          color: Qt.alpha(view.textColor, 0.75)
          font.family: view.textFont
          font.pixelSize: 13
        }
      }
    }
  }
}
