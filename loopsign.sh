#!/bin/bash

LOG_FILE="/home/loopsign/loopsign.log"

# --- Logging ---
log() {
    local TIMESTAMP
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$TIMESTAMP $1" | tee -a "$LOG_FILE"
}

log "Script started."

# --- Platform tag (replaces Pi model detection) ---
HW="x86"

# --- Get Chromium version ---
CHROMIUM_VERSION=$(chromium-browser --version 2>/dev/null | awk '{print $2}')
if [ -z "$CHROMIUM_VERSION" ]; then
    CHROMIUM_VERSION=$(chromium --version 2>/dev/null | awk '{print $2}')
fi

# --- Extract display info via xrandr (replaces wlr-randr) ---
XRANDR_OUTPUT=$(xrandr)

# Find the connected, active output (e.g. HDMI-1, DP-1, eDP-1)
DISPLAY_NAME=$(echo "$XRANDR_OUTPUT" | awk '/ connected/ {print $1; exit}')

# Get resolution and refresh rate of the current mode (marked with *)
RES_LINE=$(echo "$XRANDR_OUTPUT" | grep '\*' | head -n1)
ACTIVE_RES=$(echo "$RES_LINE" | awk '{print $1}')
ACTIVE_HZ=$(echo "$RES_LINE" | grep -oP '\d+\.\d+\*' | grep -oP '\d+\.\d+')
ACTIVE_HZ=$(printf "%.0f" "${ACTIVE_HZ:-0}")

# Physical size in mm (from xrandr output line for the connected display)
PHYSICAL_SIZE=$(echo "$XRANDR_OUTPUT" | grep -A1 "^${DISPLAY_NAME} connected" | grep -oP '\d+mm x \d+mm' | head -n1 | sed 's/mm x /x/' | sed 's/mm//')

# Fallbacks
DISPLAY_NAME=${DISPLAY_NAME:-UnknownDisplay}
PHYSICAL_SIZE=${PHYSICAL_SIZE:-0x0}
ACTIVE_RES=${ACTIVE_RES:-0x0}
ACTIVE_HZ=${ACTIVE_HZ:-0}

log "Display: $DISPLAY_NAME | Size: ${PHYSICAL_SIZE}mm | Res: $ACTIVE_RES @ ${ACTIVE_HZ}Hz"

# --- Construct custom UA tag ---
TAG="LoopSignPlayer/${HW}-2025.5:${DISPLAY_NAME// /_}_${PHYSICAL_SIZE}_${ACTIVE_RES}@${ACTIVE_HZ}"

# --- Compose final UA ---
DEFAULT_UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/${CHROMIUM_VERSION} Safari/537.36"
FINAL_UA="$DEFAULT_UA $TAG"

log "Final UA: $FINAL_UA"

# --- Clean up Chromium singleton lock ---
rm -f /home/loopsign/snap/chromium/current/.config/chromium/Singleton*

# --- Mark session as clean to suppress crash restore dialog ---
sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' /home/loopsign/snap/chromium/current/.config/chromium/Default/Preferences 2>/dev/null
sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' /home/loopsign/snap/chromium/current/.config/chromium/Default/Preferences 2>/dev/null

# --- Load hash ---
HASH=$(cat /home/loopsign/Desktop/.hash.txt)

# --- Launch Chromium in kiosk mode ---
log "Launching Chromium..."
chromium-browser \
    --disable-media-stream \
    --kiosk \
    --disable-desktop-notifications \
    --no-first-run \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --user-agent="$FINAL_UA" \
    "https://play.loopsign.eu/hash/$HASH"
