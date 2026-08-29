#!/usr/bin/env bash
# install.sh — replicate / extend the terminal + window-management setup.
#
# DEFAULT components (installed when you pass no args, or 'all'):
#   kitty       kitty terminal + JetBrains Mono Nerd Font + dropdown config
#   skhd        global hotkey daemon (Ctrl+Shift+Esc dropdown) + skhdrc
#   aerospace   AeroSpace tiling window manager + config
#
# OPTIONAL components (only installed when named explicitly):
#   rectangle   window snapping (non-tiling alternative to AeroSpace)
#   maccy       clipboard manager
#   ice         menu bar manager (Ice)
#   linearmouse mouse behaviour customiser
#   iterm       iTerm2 terminal emulator
#
# Usage:
#   bash install.sh                     # install the DEFAULT set
#   bash install.sh all                 # same as no args
#   bash install.sh list                # list everything installable & exit
#   bash install.sh kitty rectangle     # any combination (default + optional)
#   bash install.sh rectangle maccy     # just the optional ones
#
# Flags:
#   --no-font   with 'kitty' or 'all', skip installing the Nerd Font
#
# Run from inside the 'terminal-setup' folder.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ---- Component catalog ----------------------------------------------
list_components() {
  cat <<'EOF'
Installable components:

  DEFAULT (installed with no args or 'all'):
    kitty        kitty terminal + JetBrains Mono Nerd Font + dropdown config
    skhd         global hotkey daemon (Ctrl+Shift+Esc dropdown) + skhdrc
    aerospace    AeroSpace tiling window manager + config

  OPTIONAL (install only when named explicitly):
    rectangle    window snapping (non-tiling alternative to AeroSpace)
    maccy        clipboard manager
    ice          menu bar manager (Ice)
    linearmouse  mouse behaviour customiser
    iterm        iTerm2 terminal emulator
    pear         Pear Desktop (YouTube Music client)
    chrome       Google Chrome
    vscode       Visual Studio Code

Examples:
    bash install.sh                    # default set
    bash install.sh rectangle maccy    # just these two
    bash install.sh kitty rectangle    # mix default + optional
    bash install.sh chrome vscode pear # just apps
    bash uninstall.sh --help           # removal
EOF
}

# ---- Parse arguments -------------------------------------------------
DO_KITTY=0 DO_SKHD=0 DO_AERO=0
DO_RECT=0 DO_MACCY=0 DO_ICE=0 DO_LMOUSE=0 DO_ITERM=0
DO_PEAR=0 DO_CHROME=0 DO_VSCODE=0
WANT_FONT=1
COMPONENTS=()
for arg in "$@"; do
  case "$arg" in
    list|--list|-l) list_components; exit 0 ;;
    --no-font) WANT_FONT=0 ;;
    kitty|skhd|aerospace|all) COMPONENTS+=("$arg") ;;
    rectangle|maccy|ice|linearmouse|iterm) COMPONENTS+=("$arg") ;;
    pear|chrome|vscode) COMPONENTS+=("$arg") ;;
    *) echo "Unknown argument: $arg" >&2
       echo "Run 'bash install.sh list' to see valid components." >&2
       exit 2 ;;
  esac
done
if [ "${#COMPONENTS[@]}" -eq 0 ]; then COMPONENTS=("all"); fi
for c in "${COMPONENTS[@]}"; do
  case "$c" in
    all)         DO_KITTY=1; DO_SKHD=1; DO_AERO=1 ;;
    kitty)       DO_KITTY=1 ;;
    skhd)        DO_SKHD=1 ;;
    aerospace)   DO_AERO=1 ;;
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

echo "==> Checking Homebrew..."
if ! command -v brew >/dev/null 2>&1; then
  echo "ERROR: Homebrew not found. Install it from https://brew.sh first." >&2
  exit 1
fi
BREW_PREFIX="$(brew --prefix)"

# Helper: install a simple cask (optional apps have no config of ours).
install_cask() {  # $1 = cask name, $2 = human label
  echo "==> Installing $2..."
  brew install --cask "$1" || true
}

# ---- Component: kitty + font ----------------------------------------
install_kitty() {
  echo "==> Installing kitty..."
  brew install --cask kitty || true
  if [ "$WANT_FONT" -eq 1 ]; then
    echo "==> Installing JetBrains Mono Nerd Font..."
    brew install --cask font-jetbrains-mono-nerd-font || true
  else
    echo "   (skipping Nerd Font per --no-font)"
  fi
  echo "==> Placing kitty config..."
  mkdir -p "$HOME/.config/kitty"
  cp "kitty/kitty.conf"                 "$HOME/.config/kitty/kitty.conf"
  cp "kitty/theme.conf"                 "$HOME/.config/kitty/theme.conf"
  cp "kitty/quick-access-terminal.conf" "$HOME/.config/kitty/quick-access-terminal.conf"
}

# ---- Component: skhd -------------------------------------------------
install_skhd() {
  echo "==> Installing skhd..."
  SKHD_LOG="$SCRIPT_DIR/skhd-install.log"
  if ! command -v skhd >/dev/null 2>&1; then
    echo "   Trying Homebrew install first..."
    if brew install koekeishiya/formulae/skhd 2>>"$SKHD_LOG"; then
      echo "   skhd installed via Homebrew."
    else
      {
        echo "----------------------------------------"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Homebrew install of skhd failed."
        echo "Falling back to building from source."
      } >>"$SKHD_LOG"
      echo "   Homebrew install failed; see $SKHD_LOG. Building skhd from source..."
      TMP="$(mktemp -d)"
      git clone --depth 1 https://github.com/koekeishiya/skhd.git "$TMP/skhd" 2>>"$SKHD_LOG"
      ( cd "$TMP/skhd" && make && codesign -fs - ./bin/skhd \
          && cp ./bin/skhd "$BREW_PREFIX/bin/skhd" && chmod +x "$BREW_PREFIX/bin/skhd" ) 2>>"$SKHD_LOG"
      rm -rf "$TMP"
    fi
  fi
  echo "   skhd: $(command -v skhd) ($(skhd --version 2>/dev/null || echo '?'))"
  echo "==> Placing skhdrc..."
  cp "skhdrc" "$HOME/.skhdrc"
  echo "==> Registering skhd login service..."
  skhd --install-service || true
}

# ---- Component: AeroSpace -------------------------------------------
install_aerospace() {
  echo "==> Installing AeroSpace (tiling window manager)..."
  if [ ! -d "/Applications/AeroSpace.app" ] && ! command -v aerospace >/dev/null 2>&1; then
    brew install --cask nikitabobko/tap/aerospace || true
  else
    echo "   AeroSpace already installed."
  fi
  echo "   aerospace: $(command -v aerospace 2>/dev/null || echo '(app bundle only)')"
  echo "==> Placing AeroSpace config..."
  mkdir -p "$HOME/.config/aerospace"
  cp "aerospace/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"
  configure_macos_for_aerospace
}

# Apply macOS tweaks that pair well with a tiling WM. Previous values are
# backed up to this file so `uninstall.sh aerospace` can restore them.
MACOS_BACKUP="$HOME/.config/aerospace/.macos-defaults.bak"
configure_macos_for_aerospace() {
  echo "==> Tweaking macOS for AeroSpace (Dock + Launchpad pinch gesture)..."

  # Save the current values ONCE (don't clobber an existing backup).
  if [ ! -f "$MACOS_BACKUP" ]; then
    {
      echo "# Saved by terminal-setup install.sh on $(date)"
      echo "dock.autohide=$(defaults read com.apple.dock autohide 2>/dev/null || echo MISSING)"
      echo "dock.autohide-delay=$(defaults read com.apple.dock autohide-delay 2>/dev/null || echo MISSING)"
      echo "dock.no-bouncing=$(defaults read com.apple.dock no-bouncing 2>/dev/null || echo MISSING)"
      echo "dock.workspaces-auto-swoosh=$(defaults read com.apple.dock workspaces-auto-swoosh 2>/dev/null || echo MISSING)"
      for pos in tl tr bl br; do
        echo "dock.wvous-${pos}-corner=$(defaults read com.apple.dock wvous-${pos}-corner 2>/dev/null || echo MISSING)"
      done
      echo "mt.TrackpadFourFingerPinchGesture=$(defaults read com.apple.AppleMultitouchTrackpad TrackpadFourFingerPinchGesture 2>/dev/null || echo MISSING)"
      echo "bt.TrackpadFourFingerPinchGesture=$(defaults read com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerPinchGesture 2>/dev/null || echo MISSING)"
      echo "mt.TrackpadFourFingerVertSwipeGesture=$(defaults read com.apple.AppleMultitouchTrackpad TrackpadFourFingerVertSwipeGesture 2>/dev/null || echo MISSING)"
      echo "bt.TrackpadFourFingerVertSwipeGesture=$(defaults read com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerVertSwipeGesture 2>/dev/null || echo MISSING)"
      echo "mt.TrackpadThreeFingerVertSwipeGesture=$(defaults read com.apple.AppleMultitouchTrackpad TrackpadThreeFingerVertSwipeGesture 2>/dev/null || echo MISSING)"
      echo "bt.TrackpadThreeFingerVertSwipeGesture=$(defaults read com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerVertSwipeGesture 2>/dev/null || echo MISSING)"
      echo "ua.CursorMagnificationJumpToShake=$(defaults read com.apple.universalaccess CursorMagnificationJumpToShake 2>/dev/null || echo MISSING)"
      echo "g.AppleInterfaceStyle=$(defaults read -g AppleInterfaceStyle 2>/dev/null || echo MISSING)"
    } > "$MACOS_BACKUP"
    echo "   (saved previous values to $MACOS_BACKUP)"
  fi

  # 1) Hide the Dock ("bottom application tab") so it effectively never shows:
  #    auto-hide ON + a huge reveal delay (so a mouse bump won't reveal it) +
  #    no icon bouncing.
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock autohide-delay -float 1000
  defaults write com.apple.dock no-bouncing -bool true

  # 1b) Stop macOS from swooshing to another Space when you activate an app
  #     ("switch to a Space with open windows for the application"). This is
  #     a major source of workspace-jump conflicts with AeroSpace.
  defaults write com.apple.dock workspaces-auto-swoosh -bool false

  # 1c) Disable any hot corner set to "Quick Note" (action 14), which opens
  #     Notes when the pointer hits that screen corner. Set it to 0 (none).
  for pos in tl tr bl br; do
    if [ "$(defaults read com.apple.dock wvous-${pos}-corner 2>/dev/null || echo 0)" = "14" ]; then
      defaults write com.apple.dock "wvous-${pos}-corner" -int 0
    fi
  done

  # 2) Disable the "pinch to show DESKTOP" trackpad gesture (spread thumb +
  #    3 fingers). Apple calls it the FourFingerPinch. 2 = on, 0 = off.
  #    (The "show apps"/Launchpad FiveFingerPinch is left ENABLED on purpose.)
  #    Set it in BOTH the built-in and Bluetooth trackpad domains.
  defaults write com.apple.AppleMultitouchTrackpad             TrackpadFourFingerPinchGesture -int 0
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerPinchGesture -int 0

  # 2b) Disable the Mission Control / App Exposé SWIPE gestures (4- and
  #     3-finger vertical swipes), which conflict with AeroSpace's virtual
  #     workspaces.
  for dom in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do
    defaults write "$dom" TrackpadFourFingerVertSwipeGesture  -int 0
    defaults write "$dom" TrackpadThreeFingerVertSwipeGesture -int 0
  done

  # 2c) Disable the Mission Control KEY (F3-position media key) + its alt at
  #     the OS level. macOS ignores a symbolic-hotkey entry that lacks the
  #     'value' dict, so we write the COMPLETE entry with enabled=false.
  #     32 = Mission Control, 34 = Mission Control (alt). NOTE: the physical
  #     media key is re-read at login, so this fully applies after logout.
  local shk="$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"
  for id in 32 34; do
    /usr/libexec/PlistBuddy -c "Delete :AppleSymbolicHotKeys:$id" "$shk" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:$id dict" "$shk" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:$id:enabled bool false" "$shk" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:$id:value dict" "$shk" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:$id:value:type string standard" "$shk" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:$id:value:parameters array" "$shk" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:$id:value:parameters:0 integer 65535" "$shk" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:$id:value:parameters:1 integer 160" "$shk" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:$id:value:parameters:2 integer 8388608" "$shk" 2>/dev/null || true
  done
  /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u 2>/dev/null || true

  # 3) Disable "shake mouse pointer to locate" (the cursor-grows-huge effect).
  defaults write com.apple.universalaccess CursorMagnificationJumpToShake -bool false

  # 4) Set the system appearance to Dark mode.
  defaults write -g AppleInterfaceStyle -string "Dark"
  osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true' 2>/dev/null || true

  # Apply immediately.
  killall cfprefsd 2>/dev/null || true
  killall Dock 2>/dev/null || true
  killall SystemUIServer 2>/dev/null || true
  echo "   Dock effectively hidden (auto-hide + 1000s delay + no bounce);"
  echo "   app-activation Space-swoosh OFF;"
  echo "   Quick-Note hot corner OFF; show-DESKTOP pinch OFF (show-apps kept ON);"
  echo "   Mission Control swipe + F3 key OFF; shake-cursor OFF; Dark mode ON."
  echo "   (Trackpad gesture change may need a logout/login to fully apply.)"
}

# ---- Component: Rectangle (with your gap preferences) ---------------
install_rectangle() {
  install_cask rectangle "Rectangle (window snapping)"
  echo "==> Applying Rectangle preferences (10px gap, no top-edge gap)..."
  defaults write com.knollsoft.Rectangle gapSize -int 10
  defaults write com.knollsoft.Rectangle skipGapTopEdge -int 1
  # Restart Rectangle so it picks up the new prefs (if running).
  osascript -e 'quit app "Rectangle"' 2>/dev/null || true
  sleep 1
  open -a Rectangle 2>/dev/null || true
  echo "   gapSize=10, skipGapTopEdge=1 applied."
}

# ---- Run selected components ----------------------------------------
[ "$DO_KITTY"  -eq 1 ] && install_kitty
[ "$DO_SKHD"   -eq 1 ] && install_skhd
[ "$DO_AERO"   -eq 1 ] && install_aerospace
[ "$DO_RECT"   -eq 1 ] && install_rectangle
[ "$DO_MACCY"  -eq 1 ] && install_cask maccy           "Maccy (clipboard manager)"
[ "$DO_ICE"    -eq 1 ] && install_cask jordanbaird-ice "Ice (menu bar manager)"
[ "$DO_LMOUSE" -eq 1 ] && install_cask linearmouse     "LinearMouse"
[ "$DO_ITERM"  -eq 1 ] && install_cask iterm2          "iTerm2"
[ "$DO_PEAR"   -eq 1 ] && install_cask pear-devs/pear/pear-desktop "Pear Desktop (YouTube Music)"
[ "$DO_CHROME" -eq 1 ] && install_cask google-chrome    "Google Chrome"
[ "$DO_VSCODE" -eq 1 ] && install_cask visual-studio-code "Visual Studio Code"

# ---- Final notes -----------------------------------------------------
echo ""
echo "============================================================"
echo " Almost done — MANUAL steps for some components:"
echo ""
if [ "$DO_SKHD" -eq 1 ] || [ "$DO_AERO" -eq 1 ] || [ "$DO_RECT" -eq 1 ] || [ "$DO_LMOUSE" -eq 1 ]; then
  echo " Grant Accessibility permission:"
  echo "   System Settings -> Privacy & Security -> Accessibility"
  [ "$DO_SKHD" -eq 1 ]   && echo "     -> add  $BREW_PREFIX/bin/skhd        -> ON"
  [ "$DO_AERO" -eq 1 ]   && echo "     -> add  /Applications/AeroSpace.app   -> ON"
  [ "$DO_RECT" -eq 1 ]   && echo "     -> add  Rectangle                     -> ON  (prompts on 1st launch)"
  [ "$DO_LMOUSE" -eq 1 ] && echo "     -> add  LinearMouse                   -> ON  (prompts on 1st launch)"
fi
[ "$DO_SKHD" -eq 1 ] && echo " Start skhd:        skhd --start-service"
[ "$DO_AERO" -eq 1 ] && echo " Start AeroSpace:   open -a AeroSpace   (fully quit & reopen once after granting)"
[ "$DO_RECT" -eq 1 ] && echo " Launch Rectangle:  open -a Rectangle   (grant Accessibility when prompted)"
[ "$DO_ICE"  -eq 1 ] && echo " Launch Ice:        open -a Ice"
[ "$DO_MACCY" -eq 1 ] && echo " Launch Maccy:      open -a Maccy"
[ "$DO_LMOUSE" -eq 1 ] && echo " Launch LinearMouse: open -a LinearMouse"
[ "$DO_ITERM" -eq 1 ] && echo " iTerm2 installed:  open -a iTerm"
[ "$DO_PEAR" -eq 1 ]  && echo " Pear/YT Music:     open -a \"YouTube Music\""
[ "$DO_CHROME" -eq 1 ] && echo " Chrome installed:  open -a \"Google Chrome\""
[ "$DO_VSCODE" -eq 1 ] && echo " VS Code installed: open -a \"Visual Studio Code\"  (or: code .)"
echo ""
[ "$DO_SKHD" -eq 1 ]  && echo "   * Ctrl + Shift + Escape     -> toggle the kitty dropdown"
[ "$DO_AERO" -eq 1 ]  && echo "   * Alt + 1..9 / Alt+H/J/K/L  -> AeroSpace workspaces / focus"
[ "$DO_AERO" -eq 1 ]  && echo "   * Alt + Shift + ;           -> AeroSpace \"service\" mode (esc reloads)"
[ "$DO_RECT" -eq 1 ] && [ "$DO_AERO" -eq 1 ] && echo "   NOTE: Rectangle + AeroSpace both manage windows — you"
[ "$DO_RECT" -eq 1 ] && [ "$DO_AERO" -eq 1 ] && echo "         usually want ONE of them. Pick your preference."
[ "$DO_KITTY" -eq 1 ] && echo "   * Fully quit & relaunch kitty so the font loads: Cmd+Q"
echo "============================================================"
