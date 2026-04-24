#!/usr/bin/env bash
set -euo pipefail

export XAUTHORITY="${XAUTHORITY:-/home/loopsign/.Xauthority}"
export MOZ_DISABLE_RDD_SANDBOX=1
export LIBVA_DRIVER_NAME="${LIBVA_DRIVER_NAME:-iHD}"

BASE_DIR="/home/loopsign"
REPO_DIR="$BASE_DIR/ls-x86xubuntu"
LOG_FILE="$BASE_DIR/loopsign.log"
HASH_FILE="$BASE_DIR/Desktop/.hash.txt"

FIREFOX_PROFILE="loopsign"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

log "loopsign.sh started."

xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true

if [[ ! -f "$HASH_FILE" ]]; then
  log "Hash file missing. Running hashgenerator.sh."
  "$REPO_DIR/hashgenerator.sh"
fi

HASH="$(cat "$HASH_FILE" | tr -d '[:space:]')"

if [[ -z "$HASH" ]]; then
  log "Error: hash is empty."
  exit 1
fi

URL="https://play.loopsign.eu/hash/$HASH"

XRANDR_OUTPUT="$(xrandr 2>/dev/null || true)"
DISPLAY_OUTPUT="$(echo "$XRANDR_OUTPUT" | awk '/ connected/ {print $1; exit}')"
ACTIVE_RES="$(echo "$XRANDR_OUTPUT" | awk '/\*/ {print $1; exit}')"
ACTIVE_HZ="$(echo "$XRANDR_OUTPUT" | awk '/\*/ {for (i=1;i<=NF;i++) if ($i ~ /\*/) print $i}' | sed 's/*//' | head -n1)"

DISPLAY_OUTPUT="${DISPLAY_OUTPUT:-UnknownDisplay}"
ACTIVE_RES="${ACTIVE_RES:-UnknownResolution}"
ACTIVE_HZ="${ACTIVE_HZ:-UnknownHz}"

FIREFOX_VERSION="$(firefox --version 2>/dev/null || echo unknown)"

log "Display output: $DISPLAY_OUTPUT"
log "Active resolution: $ACTIVE_RES"
log "Active refresh rate: $ACTIVE_HZ"
log "Firefox version: $FIREFOX_VERSION"
log "URL: $URL"

pkill firefox >/dev/null 2>&1 || true
sleep 2

log "Starting Firefox kiosk."

exec firefox \
  -P "$FIREFOX_PROFILE" \
  --kiosk \
  --new-window "$URL"
