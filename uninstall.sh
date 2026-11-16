#!/bin/bash
# Removes omarchy-island and puts Omarchy back as it was.
#
#   ./uninstall.sh              remove the island, its clones and links,
#                               restore the shell.json saved at install time
#   ./uninstall.sh --keep-config  same, but keep your current shell.json
set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/tools/lib.sh"

say "stopping the island (the Omarchy bar comes back)"
systemctl --user disable --now omarchy-island.service >/dev/null 2>&1 || true
rm -f "$HOME/.config/systemd/user/omarchy-island.service"
systemctl --user daemon-reload
omarchy-toggle-bar off >/dev/null 2>&1 || true

rm -f "$HOME/.config/omarchy/hooks/post-update.d/omarchy-island.hook"
[[ -L $HOME/.config/quickshell/island ]] && rm "$HOME/.config/quickshell/island"
if [[ -d $STATE/quickshell-island.before-install ]]; then
  mv "$STATE/quickshell-island.before-install" "$HOME/.config/quickshell/island"
fi

# Clones created by the installer go away and the built-ins come back.
if [[ -f $STATE/created ]]; then
  while IFS= read -r id; do
    [[ -n $id && -d $PLUGINS/$id ]] || continue
    src=$(jq -r '.omarchy.clonedFrom // empty' "$PLUGINS/$id/manifest.json")
    omarchy-shell shell setPluginEnabled "$id" false >/dev/null 2>&1 || true
    rm -rf "${PLUGINS:?}/$id"
    [[ -n $src ]] && omarchy-shell shell setPluginEnabled "$src" true >/dev/null 2>&1 || true
    say "removed $id, back to $src"
  done <"$STATE/created"
fi
# Clones you had before installing stay, with the island look; say so.
for x in "${PANELS[@]}"; do
  d=$(clone_dir "$x") || continue
  grep -qx "$(basename "$d")" "$STATE/created" 2>/dev/null && continue
  warn "kept your own clone $(basename "$d") (it has island changes; remove it with: omarchy plugin remove $(basename "$d"))"
done

if [[ -L $PLUGINS/island.osd ]]; then
  omarchy-shell shell setPluginEnabled island.osd false >/dev/null 2>&1 || true
  rm "$PLUGINS/island.osd"
fi
omarchy-shell shell setPluginEnabled omarchy.osd true >/dev/null 2>&1 || true

if [[ ${1:-} != --keep-config && -f $STATE/shell.json.before-install ]]; then
  cp "$SHELL_JSON" "$STATE/shell.json.at-uninstall" 2>/dev/null || true
  cp "$STATE/shell.json.before-install" "$SHELL_JSON"
  say "restored your shell.json from before the install (current one saved as $STATE/shell.json.at-uninstall)"
fi
rm -f "$STATE/installed" "$STATE/created"
omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
omarchy-restart-shell >/dev/null 2>&1 || true
say "omarchy-island removed"
