// Pill-shaped notification inside the island: round icon on the left
// (concentric with the curve), text in the middle, actions as small pills
// on the right and the × at the end. All in a single strip, so the shape
// stays a true pill even with buttons.
import QtQuick
import "I18n.js" as I18n
import Quickshell.Widgets

Item {
  id: view
  property var info: null           // { app, summary, body, iconSource, glyph }
  property var deeds: []            // [{ kind, label, value }]
  property int more: 0              // more queued notifications (from other apps)
  property color accent: "white"
  property color textColor: "white"
  property color subColor: "gray"
  property string textFont: "sans"
  property string glyphFont: "monospace"
  readonly property var shownDeeds: deeds.slice(0, 2)
  readonly property bool hasActions: shownDeeds.length > 0
  readonly property bool hovered: hover.hovered
  // Attached screenshot/image: becomes a thumbnail you can drag anywhere.
  readonly property string image: info && info.image ? info.image : ""
  // The screenshot is still flying towards the thumbnail: don't show it twice.
  property bool thumbHidden: false
  readonly property bool holding: thumbHover.hovered || dragger.active
  // How much room the actions need (the island widens accordingly).
  readonly property real actionsWidth: hasActions ? actions.implicitWidth + 10 : 0

  signal opened()
  signal closed()
  signal deedClicked(int index)

  HoverHandler { id: hover }
  TapHandler { onTapped: view.opened() }

  // Icon: a circle sharing its center with the pill's curve.
  // With an attached image it becomes its thumbnail, wider.
  Rectangle {
    id: iconBox
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    height: view.height
    width: view.image ? Math.round(height * 1.45) : height
    radius: height / 2
    color: Qt.alpha(view.textColor, 0.08)
    visible: !view.image
    Image {
      id: img
      anchors.fill: parent
      anchors.margins: parent.width * 0.2
      source: view.info && !view.image ? view.info.iconSource : ""
      sourceSize: Qt.size(64, 64)
      fillMode: Image.PreserveAspectFit
      visible: status === Image.Ready
    }
    Text {
      anchors.centerIn: parent
      visible: img.status !== Image.Ready
      readonly property string app: view.info ? view.info.app : ""
      readonly property string glyph: view.info ? view.info.glyph : ""
      text: glyph || (app ? app.charAt(0).toUpperCase() : "󰂚")
      color: view.accent
      font.family: glyph || !app ? view.glyphFont : view.textFont
      font.pixelSize: Math.round(view.height * 0.4)
      font.weight: Font.Bold
    }
  }

  // Screenshot thumbnail: pick it up and drop it into a chat, the file
  // manager, an email… (drags the real file, like Nautilus does).
  ClippingRectangle {
    id: thumb
    visible: !!view.image
    opacity: view.thumbHidden ? 0 : 1
    anchors.fill: iconBox
    radius: height / 2
    color: Qt.alpha(view.textColor, 0.08)
    border.width: 1
    border.color: Qt.alpha(view.textColor, thumbHover.hovered ? 0.35 : 0.14)
    scale: dragger.active ? 0.92 : (thumbHover.hovered ? 1.04 : 1)
    Behavior on scale { NumberAnimation { duration: 120 } }

    Image {
      id: shot
      anchors.fill: parent
      source: view.image ? "file://" + view.image : ""
      sourceSize: Qt.size(240, 160)
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: false
    }

    Drag.active: dragger.active
    Drag.dragType: Drag.Automatic
    Drag.supportedActions: Qt.CopyAction
    Drag.proposedAction: Qt.CopyAction
    Drag.mimeData: view.image ? {
      "text/uri-list": "file://" + encodeURI(view.image) + "\r\n",
      "text/plain": view.image
    } : ({})
    Drag.imageSource: view.image ? "file://" + view.image : ""
    Drag.imageSourceSize: Qt.size(180, 120)
    Drag.hotSpot.x: 90
    Drag.hotSpot.y: 60

    HoverHandler { id: thumbHover; cursorShape: dragger.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor }
    DragHandler { id: dragger; target: null }
  }

  Column {
    anchors.left: iconBox.right
    anchors.leftMargin: 12
    anchors.right: actions.left
    anchors.rightMargin: 12 + (view.more > 0 ? 44 : 0)
    anchors.verticalCenter: parent.verticalCenter
    spacing: 1
    Row {
      width: parent.width
      spacing: 7
      Text {
        id: title
        width: Math.min(implicitWidth, parent.width - appName.implicitWidth - 7)
        text: view.info ? (view.info.summary || view.info.app) : ""
        textFormat: Text.PlainText
        color: view.textColor
        elide: Text.ElideRight
        font.family: view.textFont
        font.pixelSize: 13
        font.weight: Font.DemiBold
      }
      Text {
        id: appName
        anchors.baseline: title.baseline
        visible: !!view.info && !!view.info.app && (!!view.info.summary || view.info.count > 1)
        text: view.info ? view.info.app + (view.info.count > 1 ? " · " + view.info.count : "") : ""
        textFormat: Text.PlainText
        color: view.subColor
        font.family: view.textFont
        font.pixelSize: 11
      }
    }
    Text {
      visible: !!view.info && !!view.info.body
      width: parent.width
      text: view.info ? view.info.body : ""
      textFormat: Text.PlainText
      color: Qt.alpha(view.textColor, 0.72)
      wrapMode: Text.Wrap
      elide: Text.ElideRight
      maximumLineCount: 2
      font.family: view.textFont
      font.pixelSize: 12
    }
  }

  // Actions: compact pills before the ×.
  Row {
    id: actions
    anchors.right: closeBtn.left
    anchors.rightMargin: view.hasActions ? 8 : 0
    anchors.verticalCenter: parent.verticalCenter
    spacing: 6
    Repeater {
      model: view.shownDeeds
      Rectangle {
        required property var modelData
        required property int index
        width: label.implicitWidth + 26
        height: 32
        radius: 16
        color: index === 0 ? Qt.alpha(view.accent, deedHover.hovered ? 1 : 0.9)
                           : Qt.alpha(view.textColor, deedHover.hovered ? 0.2 : 0.12)
        scale: deedTap.pressed ? 0.94 : 1
        Behavior on scale { NumberAnimation { duration: 90 } }
        Text {
          id: label
          anchors.centerIn: parent
          textFormat: Text.PlainText
          text: modelData.kind === "code" ? I18n.t("copy", modelData.value) : modelData.label
          color: index === 0 ? "white" : view.textColor
          font.family: view.textFont
          font.pixelSize: 12
          font.weight: Font.DemiBold
        }
        HoverHandler { id: deedHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { id: deedTap; gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: view.deedClicked(index) }
      }
    }
  }

  // "+N": more queued notifications.
  Rectangle {
    visible: view.more > 0
    anchors.right: closeBtn.left
    anchors.rightMargin: view.hasActions ? actions.implicitWidth + 14 : 6
    anchors.verticalCenter: parent.verticalCenter
    width: moreLabel.implicitWidth + 14; height: 22; radius: 11
    color: Qt.alpha(view.accent, 0.22)
    Text {
      id: moreLabel
      anchors.centerIn: parent
      text: "+" + view.more
      color: view.accent
      font.family: view.textFont
      font.pixelSize: 11
      font.weight: Font.Bold
    }
  }

  // × on the right, vertically centered, inset just enough to stay
  // inside the pill's curve.
  Rectangle {
    id: closeBtn
    anchors.right: parent.right
    anchors.rightMargin: 4
    anchors.verticalCenter: parent.verticalCenter
    width: 26; height: 26; radius: 13
    color: Qt.alpha(view.textColor, closeHover.hovered ? 0.24 : 0.12)
    opacity: view.hovered ? 1 : 0.55
    Behavior on opacity { NumberAnimation { duration: 140 } }
    Text {
      anchors.centerIn: parent
      text: "󰅖"
      color: view.textColor
      font.family: view.glyphFont
      font.pixelSize: 12
    }
    HoverHandler { id: closeHover; cursorShape: Qt.PointingHandCursor }
    TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: view.closed() }
  }
}
