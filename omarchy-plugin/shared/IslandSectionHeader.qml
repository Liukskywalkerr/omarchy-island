import QtQuick
import qs.Commons
import qs.Commons as Commons

// omarchy-island: island-style section header (same API as qs.Ui/PanelSectionHeader).
// No ALL CAPS: "WI-FI BAND: 5GHZ" becomes "Wi-Fi band: 5 GHz".
Item {
  id: root
  property string text: ""
  property color foreground: Commons.Color.foreground
  property string fontFamily: Style.font.family
  property real fontSize: 13

  // Like a Text: some panels read the header's font and padding.
  readonly property alias font: label.font
  property alias topPadding: label.topPadding
  property alias color: label.color
  property alias horizontalAlignment: label.horizontalAlignment
  property alias elide: label.elide

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  readonly property var keep: ({ "WI-FI": "Wi-Fi", "WIFI": "Wi-Fi", "DNS": "DNS", "IP": "IP", "IPV4": "IPv4",
    "IPV6": "IPv6", "CPU": "CPU", "GPU": "GPU", "RAM": "RAM", "SSD": "SSD", "USB": "USB", "VPN": "VPN",
    "HDMI": "HDMI", "GHZ": "GHz", "MHZ": "MHz", "AI": "AI", "PR": "PR", "UV": "UV", "LAN": "LAN", "SSID": "SSID" })

  function pretty(t) {
    var s = String(t || "")
    if (!/[A-Z]/.test(s) || /[a-z]/.test(s)) return s
    var out = s.split(/(\s+)/).map(function(w) {
      var bare = w.replace(/[:.,;()]/g, "")
      var m = bare.match(/^(\d+)(GHZ|MHZ)$/)
      if (m) return w.replace(bare, m[1] + " " + root.keep[m[2]])
      if (root.keep[bare]) return w.replace(bare, root.keep[bare])
      return w.toLowerCase()
    }).join("")
    return out.charAt(0).toUpperCase() + out.slice(1)
  }

  Text {
    id: label
    textFormat: Text.PlainText
    text: root.pretty(root.text)
    color: Qt.alpha(root.foreground, 0.55)
    font.family: "SF Pro Text"
    font.pixelSize: root.fontSize
    font.weight: Font.DemiBold
    topPadding: 2
    width: root.width > 0 ? root.width : implicitWidth
  }
}
