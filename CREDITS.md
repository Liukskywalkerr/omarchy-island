# Credits

omarchy-island stands on other people's work.

- **[Omarchy](https://github.com/basecamp/omarchy)** (MIT) — the desktop this
  is built for. `omarchy-plugin/base/` holds unmodified copies of Omarchy's
  shell plugins and `omarchy-plugin/overlay/` our modified versions of some of
  their files; `omarchy-plugin/island-osd/` started as Omarchy's OSD plugin.
  The `Island*` components in `omarchy-plugin/shared/` are restyled versions
  of Omarchy's panel components.
- **[Quickshell](https://quickshell.org)** — the toolkit the island is written in.
- **[OmaDrop](https://github.com/lucascnunes/omadrop)** by Lucas Nunes (MIT) —
  the shelf the island's drawer talks to (optional). We add three IPC calls to
  it at install time; we don't ship its code.
- **[omastats](https://github.com/crmne/omastats)** by crmne and
  **[Mirador](https://github.com/sanjyay/Mirador)** (MIT) — optional plugins
  the island restyles when they are installed.

The screenshot sound (`quickshell/sounds/shot.wav`) is synthesized from scratch
for this project and is covered by this repository's MIT license.
