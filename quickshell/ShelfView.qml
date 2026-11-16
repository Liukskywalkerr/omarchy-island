// Shelf inside the pill: it's the same shelf as Omadrop's (the Omadrop plugin),
// read from ~/.local/state/omadrop/shelf.json and modified via IPC
// (`omarchy-shell omadrop add|delivered|clear|open`).
//
//   file dragged over the pill → the pill opens and says "drop"
//   dropped                    → goes into the shelf (shake-to-shelf too)
//   stack on the left          → drag it: all files come out together
//
// Dragging out follows Omadrop's lessons: drag data set only once
// (changing it midway crashes QtWayland), and no reliable
// "cancel" — Wayland reports IgnoreAction even when the drop succeeds.
// So, once the drag ends, the shelf goes into history (recoverable from
// Omadrop) instead of vanishing.
import QtQuick
import "I18n.js" as I18n

Item {
  id: shelf

  property var items: []
  property bool hovering: false          // a file is over the pill
  property color accent: "white"
  property color textColor: "white"
  property color subColor: "gray"
  property color pillColor: "black"
  property string textFont: ""
  property string glyphFont: ""

  signal dragBegan()
  signal dragEnded()
  signal openOmadrop()
  signal clearAll()

  readonly property int count: items.length

  function kindGlyph(kind) {
    switch (kind) {
      case "image":   return "\u{F02E9}"
      case "video":   return "\u{F0567}"
      case "audio":   return "\u{F0386}"
      case "pdf":     return "\u{F0226}"
      case "archive": return "\u{F05C4}"
      case "text":    return "\u{F0219}"
      case "doc":     return "\u{F022C}"
      case "dir":     return "\u{F024B}"
      case "link":    return "\u{F0337}"
      default:        return "\u{F0214}"
    }
  }

  // ── "Drop here" state ─────────────────────────────────────────────────────
  Rectangle {
    anchors.fill: parent
    anchors.margins: 9
    radius: height / 2
    color: Qt.alpha(shelf.accent, 0.10)
    border.width: 1.5
    border.color: Qt.alpha(shelf.accent, 0.75)
    opacity: shelf.hovering ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 140 } }
    Row {
      anchors.centerIn: parent
      spacing: 10
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "\u{F01DA}"
        color: shelf.accent
        font.family: shelf.glyphFont
        font.pixelSize: 22
        SequentialAnimation on anchors.verticalCenterOffset {
          running: shelf.hovering
          loops: Animation.Infinite
          NumberAnimation { to: 3; duration: 420; easing.type: Easing.InOutSine }
          NumberAnimation { to: 0; duration: 420; easing.type: Easing.InOutSine }
        }
      }
      Column {
        anchors.verticalCenter: parent.verticalCenter
        Text {
          text: I18n.t("dropToShelf")
          color: shelf.textColor
          font.family: shelf.textFont
          font.pixelSize: 14
          font.weight: Font.DemiBold
        }
        Text {
          text: shelf.count > 0 ? I18n.t("addsTo", shelf.count) : I18n.t("thenDragAll")
          color: shelf.subColor
          font.family: shelf.textFont
          font.pixelSize: 11
        }
      }
    }
  }

  // ── Shelf contents ────────────────────────────────────────────────────────
  Item {
    id: content
    anchors.fill: parent
    opacity: shelf.hovering ? 0 : 1
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 140 } }

    // File stack: it's the handle for "drag all".
    Item {
      id: stack
      anchors.left: parent.left
      anchors.leftMargin: 16
      anchors.verticalCenter: parent.verticalCenter
      width: 62; height: 62

      property bool dragActive: false
      property bool dragArmed: false
      property bool dragEnding: false
      property point pressPos: Qt.point(0, 0)
      property var dragMimeData: ({})
      property string dragImageUrl: ""

      Drag.active: dragActive
      Drag.dragType: Drag.Automatic
      Drag.supportedActions: Qt.CopyAction | Qt.MoveAction
      Drag.proposedAction: Qt.CopyAction
      Drag.mimeData: dragMimeData
      Drag.imageSource: dragImageUrl
      Drag.hotSpot: Qt.point(31, 31)
      Drag.onDragFinished: function(action) { stack.finishDrag() }
      Connections {
        target: stack.Drag
        function onActiveChanged() { if (stack.Drag.active) stack.dragArmed = true }
      }
      Timer {
        interval: 120
        running: stack.dragActive
        repeat: true
        onTriggered: if (stack.dragArmed && !stack.dragEnding && !stack.Drag.active) stack.finishDrag()
      }
      function finishDrag() {
        if (!dragActive || dragEnding) return
        dragEnding = true
        dragActive = false
        dragArmed = false
        shelf.dragEnded()
      }

      Repeater {
        // The last three, the most recent on top.
        model: shelf.items.slice(-3)
        Rectangle {
          id: card
          required property var modelData
          required property int index
          readonly property int depth: Math.min(3, shelf.count) - 1 - index   // 0 = top
          width: 44; height: 52
          x: (stack.width - width) / 2 + (depth === 0 ? 0 : depth === 1 ? -7 : 7)
          y: (stack.height - height) / 2 + depth * 1.5
          z: -depth
          rotation: depth === 0 ? 0 : depth === 1 ? -8 : 8
          radius: 9
          color: Qt.lighter(shelf.pillColor, 1.9)
          border.width: 1
          border.color: Qt.alpha(shelf.textColor, 0.14)
          antialiasing: true
          Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
          Behavior on rotation { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
          Image {
            id: thumb
            anchors.fill: parent
            anchors.margins: 2
            visible: card.modelData.kind === "image" && status === Image.Ready
            source: card.modelData.kind === "image" && card.modelData.path ? "file://" + encodeURI(card.modelData.path) : ""
            sourceSize: Qt.size(96, 112)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            layer.enabled: true
            layer.smooth: true
          }
          Text {
            anchors.centerIn: parent
            visible: !thumb.visible
            text: shelf.kindGlyph(card.modelData.kind)
            color: card.depth === 0 ? shelf.accent : shelf.subColor
            font.family: shelf.glyphFont
            font.pixelSize: 20
          }
        }
      }
      // How many
      Rectangle {
        visible: shelf.count > 1
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: -2
        anchors.topMargin: -1
        z: 10
        width: Math.max(20, badgeText.implicitWidth + 10); height: 20
        radius: 10
        color: shelf.accent
        Text {
          id: badgeText
          anchors.centerIn: parent
          text: shelf.count
          color: shelf.pillColor
          font.family: shelf.textFont
          font.pixelSize: 11
          font.weight: Font.Bold
          font.features: { "tnum": 1 }
        }
      }

      MouseArea {
        id: stackMouse
        anchors.fill: parent
        hoverEnabled: true
        // Stays active for the whole drag even if the shelf empties.
        enabled: shelf.count > 0 || stack.dragActive
        cursorShape: stack.dragActive ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        onPressed: function(mouse) {
          stack.pressPos = Qt.point(mouse.x, mouse.y)
          stack.dragEnding = false
          stack.dragArmed = false
          stack.grabToImage(function(r) { stack.dragImageUrl = r.url })
        }
        onPositionChanged: function(mouse) {
          if (!pressed || stack.dragActive) return
          const dist = Math.abs(mouse.x - stack.pressPos.x) + Math.abs(mouse.y - stack.pressPos.y)
          if (dist < Qt.styleHints.startDragDistance) return
          const uris = [], paths = []
          for (const it of shelf.items) { uris.push(it.uri); paths.push(it.path || it.uri) }
          if (!uris.length) return
          // Fixed reference for the whole drag.
          stack.dragMimeData = {
            "text/uri-list": uris.join("\r\n") + "\r\n",
            "text/plain": paths.join("\n")
          }
          shelf.dragBegan()
          stack.dragActive = true
        }
        onClicked: if (!stack.dragActive) shelf.openOmadrop()
      }
    }

    Column {
      anchors.left: stack.right
      anchors.leftMargin: 14
      anchors.right: buttons.left
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2
      Text {
        text: shelf.count === 1 ? I18n.t("oneFile") : I18n.t("files", shelf.count)
        color: shelf.textColor
        font.family: shelf.textFont
        font.pixelSize: 14
        font.weight: Font.DemiBold
      }
      Text {
        width: parent.width
        text: shelf.items.slice().reverse().map(function(i) { return i.name }).join(", ")
        elide: Text.ElideRight
        color: shelf.subColor
        font.family: shelf.textFont
        font.pixelSize: 11
      }
      Text {
        text: I18n.t("dragPile")
        color: Qt.alpha(shelf.accent, 0.9)
        font.family: shelf.textFont
        font.pixelSize: 11
      }
    }

    Row {
      id: buttons
      anchors.right: parent.right
      anchors.rightMargin: 16
      anchors.verticalCenter: parent.verticalCenter
      spacing: 8
      Repeater {
        model: [{ glyph: "\u{F0770}", act: "open" }, { glyph: "\u{F0156}", act: "clear" }]
        Rectangle {
          required property var modelData
          width: 32; height: 32; radius: 16
          color: btnHover.hovered ? Qt.alpha(shelf.textColor, 0.16) : Qt.alpha(shelf.textColor, 0.08)
          Behavior on color { ColorAnimation { duration: 120 } }
          Text {
            anchors.centerIn: parent
            text: modelData.glyph
            color: shelf.textColor
            font.family: shelf.glyphFont
            font.pixelSize: 15
          }
          HoverHandler { id: btnHover; cursorShape: Qt.PointingHandCursor }
          TapHandler {
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: modelData.act === "open" ? shelf.openOmadrop() : shelf.clearAll()
          }
        }
      }
    }
  }
}
