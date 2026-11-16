// UI strings. English by default; Italian when the system locale is Italian.
// The locale comes from the environment of the island process (LANG/LC_ALL),
// e.g. `LC_ALL=en_US.UTF-8 qs -c island` forces English.
.pragma library

var strings = {
  en: {
    nothingPlaying: "Nothing playing",
    on: "On", off: "Off", active: "Active",
    caffeine: "Caffeine", caffeineOn: "Screen stays awake",
    dnd: "Do Not Disturb",
    screenshot: "Screenshot", record: "Record", weather: "Weather", calendar: "Calendar",
    notifications: "Notifications", timezones: "Time zones", menu: "Menu", system: "System",
    github: "GitHub", agents: "Agents", omadrop: "Omadrop", battery: "Battery",
    update: "Update", lock: "Lock",
    batteryLow: "Battery low", charging: "Charging",
    copy: "Copy %1",
    today: "Today", yesterday: "Yesterday", minAgo: "%1 min ago", now: "now",
    clearAll: "Clear", sure: "Sure?", noNotifications: "No notifications",
    dropToShelf: "Drop into the shelf",
    addsTo: "joins the %1 already inside",
    thenDragAll: "then drag them all out at once",
    files: "%1 files", oneFile: "1 file",
    dragPile: "drag the stack to move them all",
    testTitle: "Hello there 👋", testBody: "This is a test notification inside the island.",
    testShot: "Screenshot saved and copied", testShotBody: "Drag the thumbnail anywhere"
  },
  it: {
    nothingPlaying: "Niente in riproduzione",
    on: "Acceso", off: "Spento", active: "Attivo",
    caffeine: "Caffeine", caffeineOn: "Schermo sempre acceso",
    dnd: "Non disturbare",
    screenshot: "Screenshot", record: "Registra", weather: "Meteo", calendar: "Calendario",
    notifications: "Notifiche", timezones: "Fusi orari", menu: "Menu", system: "Sistema",
    github: "GitHub", agents: "Agenti", omadrop: "Omadrop", battery: "Batteria",
    update: "Aggiorna", lock: "Blocca",
    batteryLow: "Batteria scarica", charging: "In carica",
    copy: "Copia %1",
    today: "Oggi", yesterday: "Ieri", minAgo: "%1 min fa", now: "ora",
    clearAll: "Cancella", sure: "Sicuro?", noNotifications: "Nessuna notifica",
    dropToShelf: "Rilascia nel cassetto",
    addsTo: "si aggiungono ai %1 già dentro",
    thenDragAll: "poi li trascini fuori tutti insieme",
    files: "%1 file", oneFile: "1 file",
    dragPile: "trascina la pila per spostarli tutti",
    testTitle: "Ciao 👋", testBody: "Questa è una notifica di prova dentro l'isola.",
    testShot: "Screenshot salvato e copiato", testShotBody: "Trascina la miniatura dove vuoi"
  }
}

function detect() {
  try {
    var n = String(Qt.locale().name || "").slice(0, 2).toLowerCase()
    return strings[n] ? n : "en"
  } catch (e) { return "en" }
}
var lang = detect()

function setLang(code) {
  var c = String(code || "").toLowerCase().slice(0, 2)
  lang = strings[c] ? c : "en"
}

function t(key, arg) {
  var table = strings[lang] || strings.en
  var s = table[key] !== undefined ? table[key] : (strings.en[key] !== undefined ? strings.en[key] : key)
  return arg !== undefined ? s.replace("%1", arg) : s
}
