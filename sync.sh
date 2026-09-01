#!/usr/bin/env bash
# sync.sh — copy your LIVE configs back into this terminal-setup package,
# so the package stays up-to-date with any edits you make day-to-day.
#
# Usage:  cd terminal-setup && bash sync.sh
#
# This is the reverse of install.sh (which copies FROM the package TO your
# system). Run this after tweaking any config, before copying the package
# to another machine.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

changed=0

sync_file() {  # $1 = live path, $2 = package path
  local live="$1" pkg="$SCRIPT_DIR/$2"
  if [ ! -f "$live" ]; then
    echo "  SKIP (not present): $live"
    return
  fi
  mkdir -p "$(dirname "$pkg")"
  if diff -q "$live" "$pkg" >/dev/null 2>&1; then
    echo "  OK   (unchanged):   $2"
  else
    cp "$live" "$pkg"
    echo "  SYNC (updated):     $2  ← $live"
    changed=1
  fi
}

echo "Syncing live configs → terminal-setup package..."
echo ""
sync_file "$HOME/.config/aerospace/aerospace.toml"       "aerospace/aerospace.toml"
sync_file "$HOME/.config/kitty/kitty.conf"               "kitty/kitty.conf"
sync_file "$HOME/.config/kitty/theme.conf"               "kitty/theme.conf"
sync_file "$HOME/.config/kitty/quick-access-terminal.conf" "kitty/quick-access-terminal.conf"
sync_file "$HOME/.skhdrc"                                "skhdrc"
sync_file "$HOME/.tmux.conf"                             "tmux/tmux.conf"
sync_file "$HOME/.zshrc"                                 "zshrc"
sync_file "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/engine2.zsh-theme" "zsh/themes/engine2.zsh-theme"
echo ""
if [ "$changed" -eq 1 ]; then
  echo "Package updated. Ready to copy to another machine."
else
  echo "Everything already in sync — nothing to update."
fi
