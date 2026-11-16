// "Real" name and icon of notifications, used by the island and the notification center.
//
// - Chromium webapps (WhatsApp, ...): Chromium identifies itself as "Chromium"
//   with no icon; the sending site is in `source` (web.whatsapp.com). The
//   name and icon of the webapp's launcher (~/.local/share/applications) are used.
// - KDE Connect: phone notifications arrive as app "KDE Connect" with the
//   KDE Connect icon and the phone app's name in the title
//   ("WhatsApp", "Gmail"). They become that app, with its icon, and the title
//   takes the chat/sender from the first part of the body ("Chat: message").
.pragma library

function lower(s) { return String(s || "").toLowerCase() }

// lookup(domain) -> { name, icon } of the webapp launcher, or null.
// iconOk(name) -> true if the icon theme has that icon.
function normalize(n, lookup, iconOk) {
  if (!n) return n
  const app = String(n.app || "")
  const source = String(n.source || "")
  const out = Object.assign({}, n)

  if (lower(app) === "chromium" || lower(app).startsWith("google chrome")) {
    const domain = source.replace(/^https?:\/\//, "").replace(/\/.*$/, "")
    const hit = domain && lookup ? lookup(domain) : null
    if (hit) {
      out.app = hit.name
      if (!out.appIcon || lower(out.appIcon).indexOf("chrom") >= 0) out.appIcon = hit.icon
    } else if (domain) {
      // No launcher: at least the site name instead of "Chromium".
      const base = domain.replace(/^(www|web|app|m)\./, "").split(".")[0]
      out.app = base.charAt(0).toUpperCase() + base.slice(1)
    }
    return out
  }

  if (lower(app) === "kde connect" || lower(n.appIcon) === "kdeconnect") {
    const phoneApp = String(n.summary || "").trim()
    if (!phoneApp) return out
    out.app = phoneApp
    out.appIcon = ""
    const base = lower(phoneApp)
    for (const name of [base, base.replace(/\s+/g, "-"), base.replace(/\s+/g, ""),
                        "com." + base.replace(/\s+/g, "") ]) {
      if (iconOk && iconOk(name)) { out.appIcon = name; break }
    }
    // "Chat: Sender:\ntext" / "Sender: text" -> title = Chat/Sender.
    const body = String(n.body || "")
    const m = body.match(/^([^:\n]{1,60}):\s*([\s\S]*)$/)
    if (m && m[2].trim()) {
      out.summary = m[1].trim()
      out.body = m[2].trim()
    } else {
      out.summary = ""
    }
    // Group by phone app too, rather than all under KDE Connect.
    out.groupKey = "phone:" + base
    return out
  }

  return out
}
