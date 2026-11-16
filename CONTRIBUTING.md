# Contributing

Thanks for wanting to make the island better! A few things keep it smooth.

## Before you open an issue

- Run `tools/island-sync` and paste its output: most breakages after an
  Omarchy update show up there.
- Include `omarchy version`, `qs --version` and the island log:
  `journalctl --user -u omarchy-island -n 80 --no-pager`.

## Pull requests

- One change per PR, with a screenshot or short clip for anything visual.
- Changes to Omarchy's panels go in `omarchy-plugin/overlay/<panel>/`, never in
  `~/.config/omarchy/plugins/` (those are rebuilt from the overlay). After
  editing the overlay run `tools/island-sync` to apply it.
- UI text goes through `quickshell/I18n.js` (English required, other languages
  welcome).
- QML reloads live while you edit; `systemctl --user restart omarchy-island`
  for a clean start. Test with animations on and off
  (`omarchy toggle animations`).

## Adding a language

Copy the `en` block in `quickshell/I18n.js`, translate it, and add it under its
two-letter code. The island picks it from the system locale.
