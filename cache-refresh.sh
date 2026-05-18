#!/bin/bash

REPO_DIR="/home/loopsign/ls-x86intel"
FLAG_FILE="$REPO_DIR/cache-refresh-flag"
DONE_FILE="/home/loopsign/cache-refresh-flag.done"

if [[ ! -f "$FLAG_FILE" ]]; then
  echo "No cache refresh flag found. Skipping."
  exit 0
fi

FLAG_VALUE=$(tr -d '[:space:]' < "$FLAG_FILE")
DONE_VALUE=$(cat "$DONE_FILE" 2>/dev/null | tr -d '[:space:]')

if [[ -z "$FLAG_VALUE" ]] || [[ "$FLAG_VALUE" == "$DONE_VALUE" ]]; then
  echo "Cache refresh flag already acted on ($FLAG_VALUE). Skipping."
  exit 0
fi

echo "Cache refresh flag detected ($FLAG_VALUE). Scheduling hard refresh in 5 minutes..."

sleep 300

export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY:-/home/loopsign/.Xauthority}"

xdotool search --onlyvisible --class firefox windowactivate --sync key ctrl+shift+r

echo "$FLAG_VALUE" > "$DONE_FILE"

echo "Cache refresh performed and flag consumed at $(date)."
