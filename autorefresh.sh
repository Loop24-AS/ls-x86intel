#!/bin/bash

export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY:-/home/loopsign/.Xauthority}"

LOG_FILE="/home/loopsign/autorefresh.log"

CHECK_INTERVAL_NORMAL=60
CHECK_INTERVAL_FAST=3
DISCONNECT_NOTIFY_DELAY=60

ZENITY_PID=""

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

is_connected() {
    curl -4 -sfI --connect-timeout 2 --max-time 6 https://play.loopsign.eu/ >/dev/null 2>&1
}

refresh_firefox() {
    log "Refreshing Firefox with Ctrl+R."

    xdotool search --onlyvisible --class firefox windowactivate --sync key ctrl+r >/dev/null 2>&1 || \
    xdotool search --onlyvisible --name "Mozilla Firefox" windowactivate --sync key ctrl+r >/dev/null 2>&1 || \
    log "WARNING: Could not find/refresh Firefox window."
}

show_disconnected_warning() {
    zenity --warning \
        --title="LoopSign" \
        --text="Internet connection lost.

The LoopSign player will continue automatically when the connection is restored." &

    ZENITY_PID=$!
    log "Disconnected warning shown. PID=$ZENITY_PID"
}

kill_zenity() {
    if [ -n "$ZENITY_PID" ] && kill -0 "$ZENITY_PID" 2>/dev/null; then
        kill "$ZENITY_PID" 2>/dev/null || true
        log "Disconnected warning closed. PID=$ZENITY_PID"
    fi

    ZENITY_PID=""
}

log "autorefresh.sh started."

was_connected=true
disconnect_start=0
warning_shown=false

while true; do
    if is_connected; then
        if [ "$was_connected" = false ]; then
            log "Internet connection restored."
            kill_zenity
            refresh_firefox
        fi

        was_connected=true
        disconnect_start=0
        warning_shown=false

        sleep "$CHECK_INTERVAL_NORMAL"
    else
        if [ "$was_connected" = true ]; then
            log "Internet connection lost. Starting grace period."
            disconnect_start=$(date +%s)
        fi

        was_connected=false

        now=$(date +%s)
        offline_for=$((now - disconnect_start))

        if [ "$offline_for" -ge "$DISCONNECT_NOTIFY_DELAY" ] && [ "$warning_shown" = false ]; then
            show_disconnected_warning
            warning_shown=true
        fi

        sleep "$CHECK_INTERVAL_FAST"
    fi
done
