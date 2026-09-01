#!/usr/bin/env bash
# uninstall.sh — remove components of the terminal + window-management setup.
#
# By DEFAULT this removes CONFIG FILES only (for components that have any)
# and leaves the Homebrew packages installed. Each removed config is backed
# up to <file>.bak first. Pass --apps to ALSO `brew uninstall` the apps.
#
# The optional apps (rectangle, maccy, ice, linearmouse, iterm) have no
# config of ours, so they are ONLY affected when you pass --apps.
#
# DEFAULT components (acted on with no args or 'all'):
#   kitty | skhd | aerospace
# OPTIONAL components (only when named explicitly):
#   rectangle | maccy | ice | linearmouse | iterm
#
# Usage:
#   bash uninstall.sh                   # remove ALL default configs (keep brew apps)
#   bash uninstall.sh all               # same as no args
#   bash uninstall.sh list              # list everything this can remove & exit
#   bash uninstall.sh aerospace         # remove only AeroSpace config
#   bash uninstall.sh --apps kitty      # remove kitty config AND brew-uninstall it
#   bash uninstall.sh --apps rectangle  # brew-uninstall Rectangle (no config to remove)
#   bash uninstall.sh --apps all        # full teardown of the DEFAULT set
#
# Flags:
#   --apps       also brew-uninstall the selected apps/casks
#   --no-font    when uninstalling kitty apps, keep the Nerd Font
#   --purge      delete configs WITHOUT making .bak backups
set -euo pipefail

list_components() {
  cat <<'EOF'
Removable components:

  DEFAULT (have config files; acted on with no args or 'all'):
    kitty        ~/.config/kitty/*.conf        (+ --apps: kitty cask + font)
    skhd         ~/.skhdrc + stop service      (+ --apps: skhd)
    aerospace    ~/.config/aerospace/*.toml    (+ --apps: AeroSpace cask)

  OPTIONAL (no config of ours; only touched with --apps):
    rectangle    (+ --apps: Rectangle cask)
    maccy        (+ --apps: Maccy cask)
    ice          (+ --apps: Ice cask)
    linearmouse  (+ --apps: LinearMouse cask)
    iterm        (+ --apps: iTerm2 cask)
    pear         (+ --apps: Pear Desktop / YouTube Music cask)
    chrome       (+ --apps: Google Chrome cask)
    vscode       (+ --apps: Visual Studio Code cask)

Flags: --apps (also brew-uninstall)  --no-font  --purge (no .bak backups)
EOF
}

DO_KITTY=0 DO_SKHD=0 DO_AERO=0 DO_TMUX=0 DO_ZSH=0
DO_RECT=0 DO_MACCY=0 DO_ICE=0 DO_LMOUSE=0 DO_ITERM=0
DO_PEAR=0 DO_CHROME=0 DO_VSCODE=0
UNINSTALL_APPS=0 KEEP_FONT=0 PURGE=0
COMPONENTS=()
for arg in "$@"; do
  case "$arg" in
    list|--list|-l) list_components; exit 0 ;;
    --apps)    UNINSTALL_APPS=1 ;;
    --no-font) KEEP_FONT=1 ;;
    --purge)   PURGE=1 ;;
    kitty|skhd|aerospace|tmux|zsh|all) COMPONENTS+=("$arg") ;;
    rectangle|maccy|ice|linearmouse|iterm) COMPONENTS+=("$arg") ;;
    pear|chrome|vscode) COMPONENTS+=("$arg") ;;
    *) echo "Unknown argument: $arg" >&2
       echo "Run 'bash uninstall.sh list' to see valid components." >&2
       exit 2 ;;
  esac
done
if [ "${#COMPONENTS[@]}" -eq 0 ]; then COMPONENTS=("all"); fi
for c in "${COMPONENTS[@]}"; do
  case "$c" in
    all)         DO_KITTY=1; DO_SKHD=1; DO_AERO=1; DO_TMUX=1; DO_ZSH=1 ;;
    kitty)       DO_KITTY=1 ;;
    skhd)        DO_SKHD=1 ;;
    aerospace)   DO_AERO=1 ;;
    tmux)        DO_TMUX=1 ;;
    zsh)         DO_ZSH=1 ;;
    rectangle)   DO_RECT=1 ;;
    maccy)       DO_MACCY=1 ;;
    ice)         DO_ICE=1 ;;
    linearmouse) DO_LMOUSE=1 ;;
    iterm)       DO_ITERM=1 ;;
    pear)        DO_PEAR=1 ;;
    chrome)      DO_CHROME=1 ;;
    vscode)      DO_VSCODE=1 ;;
  esac
done

# Warn if an optional (config-less) app was named without --apps.
if [ "$UNINSTALL_APPS" -eq 0 ]; then
  named_optional=0
  for v in "$DO_RECT" "$DO_MACCY" "$DO_ICE" "$DO_LMOUSE" "$DO_ITERM" "$DO_PEAR" "$DO_CHROME" "$DO_VSCODE"; do
    [ "$v" -eq 1 ] && named_optional=1
  done
  if [ "$named_optional" -eq 1 ]; then
    echo "NOTE: optional apps (rectangle/maccy/ice/linearmouse/iterm/pear/chrome/vscode)"
    echo "      have no config to remove. They are only uninstalled with --apps."
  fi
fi

BREW_PREFIX="$(brew --prefix 2>/dev/null || echo /opt/homebrew)"

remove_file() {
  local f="$1"
  if [ -e "$f" ] || [ -L "$f" ]; then
    if [ "$PURGE" -eq 1 ]; then
      rm -f "$f"; echo "   removed $f"
    else
      mv -f "$f" "$f.bak"; echo "   removed $f  (backup: $f.bak)"
    fi
  else
    echo "   (not present: $f)"
  fi
}

# Quit + brew-uninstall a cask (used for optional apps and --apps mode).
uninstall_cask() {  # $1 = cask name, $2 = app name to quit, $3 = human label
  echo "==> Uninstalling $3..."
  [ -n "${2:-}" ] && { osascript -e "quit app \"$2\"" 2>/dev/null || pkill -f "$2" 2>/dev/null || true; sleep 1; }
  brew uninstall --cask "$1" 2>/dev/null || true
}

uninstall_kitty() {
  echo "==> Removing kitty config..."
  remove_file "$HOME/.config/kitty/kitty.conf"
  remove_file "$HOME/.config/kitty/theme.conf"
  remove_file "$HOME/.config/kitty/quick-access-terminal.conf"
  rmdir "$HOME/.config/kitty" 2>/dev/null && echo "   removed empty ~/.config/kitty" || true
  if [ "$UNINSTALL_APPS" -eq 1 ]; then
    uninstall_cask kitty kitty "kitty"
    if [ "$KEEP_FONT" -eq 0 ]; then
      echo "==> brew uninstalling JetBrains Mono Nerd Font..."
      brew uninstall --cask font-jetbrains-mono-nerd-font 2>/dev/null || true
    fi
  fi
}

uninstall_skhd() {
  echo "==> Stopping skhd service..."
  skhd --stop-service 2>/dev/null || true
  echo "==> Removing skhdrc..."
  remove_file "$HOME/.skhdrc"
  if [ "$UNINSTALL_APPS" -eq 1 ]; then
    echo "==> brew uninstalling skhd..."
    brew uninstall koekeishiya/formulae/skhd 2>/dev/null \
      || brew uninstall skhd 2>/dev/null \
      || { [ -f "$BREW_PREFIX/bin/skhd" ] && rm -f "$BREW_PREFIX/bin/skhd" && echo "   removed $BREW_PREFIX/bin/skhd (source build)"; } \
      || true
  fi
}

uninstall_aerospace() {
  echo "==> Removing AeroSpace config..."
  remove_file "$HOME/.config/aerospace/aerospace.toml"
  restore_macos_defaults
  rmdir "$HOME/.config/aerospace" 2>/dev/null && echo "   removed empty ~/.config/aerospace" || true
  if [ "$UNINSTALL_APPS" -eq 1 ]; then
    echo "==> Quitting + brew uninstalling AeroSpace..."
    osascript -e 'quit app "AeroSpace"' 2>/dev/null || pkill -f AeroSpace 2>/dev/null || true
    sleep 1
    brew uninstall --cask nikitabobko/tap/aerospace 2>/dev/null \
      || brew uninstall --cask aerospace 2>/dev/null || true
  fi
}

# Restore the macOS defaults that install.sh changed for AeroSpace, using
# the backup file it wrote. MISSING means the key was unset originally, so
# we delete it to return to system default.
MACOS_BACKUP="$HOME/.config/aerospace/.macos-defaults.bak"
restore_macos_defaults() {
  if [ ! -f "$MACOS_BACKUP" ]; then
    echo "   (no macOS-defaults backup found; leaving Dock/gesture/appearance as-is)"
    return
  fi
  echo "==> Restoring macOS defaults changed for AeroSpace..."
  # shellcheck disable=SC1090
  # Parse "key=value" lines.
  local dock swoosh mt bt shake theme
  dock=$(grep    '^dock.autohide='                     "$MACOS_BACKUP" | cut -d= -f2-)
  swoosh=$(grep  '^dock.workspaces-auto-swoosh='       "$MACOS_BACKUP" | cut -d= -f2-)
  mt=$(grep      '^mt.TrackpadFourFingerPinchGesture='  "$MACOS_BACKUP" | cut -d= -f2-)
  bt=$(grep      '^bt.TrackpadFourFingerPinchGesture='  "$MACOS_BACKUP" | cut -d= -f2-)
  shake=$(grep   '^ua.CursorMagnificationJumpToShake='  "$MACOS_BACKUP" | cut -d= -f2-)
  theme=$(grep   '^g.AppleInterfaceStyle='              "$MACOS_BACKUP" | cut -d= -f2-)

  if [ "$dock" = "MISSING" ]; then defaults delete com.apple.dock autohide 2>/dev/null || true
  elif [ -n "$dock" ]; then defaults write com.apple.dock autohide -bool "$([ "$dock" = 1 ] && echo true || echo false)"; fi

  # autohide-delay: restore prior float, or delete if it was originally unset.
  delay=$(grep '^dock.autohide-delay=' "$MACOS_BACKUP" | cut -d= -f2-)
  if [ "$delay" = "MISSING" ]; then defaults delete com.apple.dock autohide-delay 2>/dev/null || true
  elif [ -n "$delay" ]; then defaults write com.apple.dock autohide-delay -float "$delay"; fi

  # no-bouncing: restore prior bool, or delete if it was originally unset.
  bounce=$(grep '^dock.no-bouncing=' "$MACOS_BACKUP" | cut -d= -f2-)
  if [ "$bounce" = "MISSING" ]; then defaults delete com.apple.dock no-bouncing 2>/dev/null || true
  elif [ -n "$bounce" ]; then defaults write com.apple.dock no-bouncing -bool "$([ "$bounce" = 1 ] && echo true || echo false)"; fi

  if [ "$swoosh" = "MISSING" ]; then defaults delete com.apple.dock workspaces-auto-swoosh 2>/dev/null || true
  elif [ -n "$swoosh" ]; then defaults write com.apple.dock workspaces-auto-swoosh -bool "$([ "$swoosh" = 1 ] && echo true || echo false)"; fi

  # Restore each hot corner to its backed-up value (delete if originally unset).
  for pos in tl tr bl br; do
    cval=$(grep "^dock.wvous-${pos}-corner=" "$MACOS_BACKUP" | cut -d= -f2-)
    if [ "$cval" = "MISSING" ]; then defaults delete com.apple.dock "wvous-${pos}-corner" 2>/dev/null || true
    elif [ -n "$cval" ]; then defaults write com.apple.dock "wvous-${pos}-corner" -int "$cval"; fi
  done

  for dom in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do
    val="$mt"; [ "$dom" != "com.apple.AppleMultitouchTrackpad" ] && val="$bt"
    if [ "$val" = "MISSING" ]; then defaults delete "$dom" TrackpadFourFingerPinchGesture 2>/dev/null || true
    elif [ -n "$val" ]; then defaults write "$dom" TrackpadFourFingerPinchGesture -int "$val"; fi
  done

  # Restore the Mission Control / Exposé swipe gestures (4- and 3-finger vert).
  for key in TrackpadFourFingerVertSwipeGesture TrackpadThreeFingerVertSwipeGesture; do
    for dom in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do
      pfx=mt; [ "$dom" != "com.apple.AppleMultitouchTrackpad" ] && pfx=bt
      v=$(grep "^${pfx}.${key}=" "$MACOS_BACKUP" | cut -d= -f2-)
      if [ "$v" = "MISSING" ]; then defaults delete "$dom" "$key" 2>/dev/null || true
      elif [ -n "$v" ]; then defaults write "$dom" "$key" -int "$v"; fi
    done
  done

  if [ "$shake" = "MISSING" ]; then defaults delete com.apple.universalaccess CursorMagnificationJumpToShake 2>/dev/null || true
  elif [ -n "$shake" ]; then defaults write com.apple.universalaccess CursorMagnificationJumpToShake -bool "$([ "$shake" = 1 ] && echo true || echo false)"; fi

  if [ "$theme" = "MISSING" ]; then
    defaults delete -g AppleInterfaceStyle 2>/dev/null || true
    osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to false' 2>/dev/null || true
  elif [ -n "$theme" ]; then defaults write -g AppleInterfaceStyle -string "$theme"; fi

  killall cfprefsd 2>/dev/null || true
  # Re-enable Mission Control / App Exposé symbolic hotkeys (F3) we disabled.
  local shk="$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"
  for id in 32 33 34; do
    /usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:$id:enabled true" "$shk" 2>/dev/null || true
  done
  /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u 2>/dev/null || true
  killall Dock 2>/dev/null || true
  killall SystemUIServer 2>/dev/null || true
  remove_file "$MACOS_BACKUP"
  echo "   Restored Dock / trackpad gesture / swipes / F3 / shake-cursor / appearance."
}

uninstall_tmux() {
  echo "==> Removing tmux config..."
  remove_file "$HOME/.tmux.conf"
  if [ "$UNINSTALL_APPS" -eq 1 ]; then
    echo "==> brew uninstalling tmux..."
    brew uninstall tmux 2>/dev/null || true
  fi
}

uninstall_zsh() {
  echo "==> Removing zsh customizations..."
  # Restore prior .zshrc backup if present, else remove ours.
  if [ -f "$HOME/.zshrc.bak" ]; then
    mv -f "$HOME/.zshrc.bak" "$HOME/.zshrc"
    echo "   restored previous ~/.zshrc from backup"
  else
    remove_file "$HOME/.zshrc"
  fi
  local ZC="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  for p in zsh-syntax-highlighting zsh-autosuggestions fzf-tab zsh-autocomplete; do
    if [ -d "$ZC/plugins/$p" ]; then rm -rf "$ZC/plugins/$p"; echo "   removed plugin $p"; fi
  done
  if [ "$UNINSTALL_APPS" -eq 1 ]; then
    echo "==> brew uninstalling fzf..."
    brew uninstall fzf 2>/dev/null || true
  fi
}

[ "$DO_KITTY" -eq 1 ] && uninstall_kitty
[ "$DO_SKHD"  -eq 1 ] && uninstall_skhd
[ "$DO_AERO"  -eq 1 ] && uninstall_aerospace
[ "$DO_TMUX"  -eq 1 ] && uninstall_tmux
[ "$DO_ZSH"   -eq 1 ] && uninstall_zsh

# Optional apps: only when --apps is given (they have no config of ours).
if [ "$UNINSTALL_APPS" -eq 1 ]; then
  [ "$DO_RECT"   -eq 1 ] && uninstall_cask rectangle       Rectangle   "Rectangle"
  [ "$DO_MACCY"  -eq 1 ] && uninstall_cask maccy           Maccy       "Maccy"
  [ "$DO_ICE"    -eq 1 ] && uninstall_cask jordanbaird-ice Ice         "Ice"
  [ "$DO_LMOUSE" -eq 1 ] && uninstall_cask linearmouse     LinearMouse "LinearMouse"
  [ "$DO_ITERM"  -eq 1 ] && uninstall_cask iterm2          iTerm       "iTerm2"
  [ "$DO_PEAR"   -eq 1 ] && uninstall_cask pear-devs/pear/pear-desktop "YouTube Music" "Pear Desktop (YouTube Music)"
  [ "$DO_CHROME" -eq 1 ] && uninstall_cask google-chrome    "Google Chrome" "Google Chrome"
  [ "$DO_VSCODE" -eq 1 ] && uninstall_cask visual-studio-code "Visual Studio Code" "Visual Studio Code"
fi

echo ""
echo "============================================================"
echo " Uninstall complete."
if [ "$UNINSTALL_APPS" -eq 0 ]; then
  echo " NOTE: Homebrew packages were KEPT (configs only were removed)."
  echo "       Re-run with  --apps  to also brew-uninstall the apps."
fi
if [ "$PURGE" -eq 0 ]; then
  echo " Backups of removed configs were saved as <file>.bak"
fi
if [ "$DO_SKHD" -eq 1 ] || [ "$DO_AERO" -eq 1 ] || [ "$DO_RECT" -eq 1 ] || [ "$DO_LMOUSE" -eq 1 ]; then
  echo " You may also want to remove leftover Accessibility entries:"
  echo "   System Settings -> Privacy & Security -> Accessibility"
  [ "$DO_SKHD" -eq 1 ]   && echo "     - remove  skhd"
  [ "$DO_AERO" -eq 1 ]   && echo "     - remove  AeroSpace"
  [ "$DO_RECT" -eq 1 ]   && echo "     - remove  Rectangle"
  [ "$DO_LMOUSE" -eq 1 ] && echo "     - remove  LinearMouse"
fi
echo "============================================================"
