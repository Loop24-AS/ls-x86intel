#!/bin/bash

exec > /tmp/loopsign.log 2>&1
echo "loopsign.sh started at $(date)"

HASH_FILE="/home/loopsign/Desktop/.hash.txt"
PLAY_BASE_URL="https://play.loopsign.eu/hash"

export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY:-/home/loopsign/.Xauthority}"

get_hash() {
    if [ -f "$HASH_FILE" ]; then
        HASH="$(tr -d '[:space:]' < "$HASH_FILE")"
    else
        HASH="unknown"
    fi

    [ -z "$HASH" ] && HASH="unknown"
    echo "$HASH"
}

close_existing_firefox() {
    pkill -TERM -f firefox || true
    sleep 2

    if pgrep -f firefox >/dev/null 2>&1; then
        pkill -KILL -f firefox || true
        sleep 1
    fi
}

HASH="$(get_hash)"
URL="$PLAY_BASE_URL/$HASH"

echo "Launching Firefox kiosk:"
echo "$URL"

close_existing_firefox

exec firefox-esr \
    --kiosk \
    --new-window "$URL"#!/bin/bash

exec > /tmp/loopsign.log 2>&1
echo "loopsign.sh started at $(date)"

REPO_DIR="/home/loopsign/ls-x86intel"
HASH_FILE="/home/loopsign/Desktop/.hash.txt"
DEFAULT_HASH="unknown"
PLAY_BASE_URL="https://play.loopsign.eu/hash"

export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY:-/home/loopsign/.Xauthority}"

disable_screen_blanking() {
    echo "Disabling X11 screen blanking and DPMS..."

    xset s off || true
    xset -dpms || true
    xset s noblank || true

    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -s 0 || true
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled -s false || true
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/presentation-mode -s true || true
}

log_display_info() {
    echo "Display information:"
    xrandr --query || true
}

get_hash() {
    if [ -f "$HASH_FILE" ]; then
        HASH="$(tr -d '[:space:]' < "$HASH_FILE")"
    else
        HASH="$DEFAULT_HASH"
    fi

    if [ -z "$HASH" ]; then
        HASH="$DEFAULT_HASH"
    fi

    echo "$HASH"
}

close_existing_firefox() {
    echo "Closing existing Firefox processes..."

    pkill -TERM -f firefox || true
    sleep 2

    if pgrep -f firefox >/dev/null 2>&1; then
        echo "Firefox still running; forcing close..."
        pkill -KILL -f firefox || true
        sleep 1
    fi
}

prepare_firefox_profile() {
    mkdir -p /home/loopsign/.cache/mozilla/firefox
    mkdir -p /home/loopsign/.mozilla/firefox
}

launch_firefox() {
    HASH="$(get_hash)"
    URL="$PLAY_BASE_URL/$HASH"

    echo "Launching Firefox kiosk:"
    echo "$URL"

    exec firefox-esr \
        --kiosk \
        --new-window "$URL"
}

cd "$REPO_DIR" || true

disable_screen_blanking
log_display_info
prepare_firefox_profile
close_existing_firefox
launch_firefox
