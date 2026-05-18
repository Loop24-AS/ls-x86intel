#!/bin/bash
set -e

OUT_DIR="/home/loopsign/player-info"
mkdir -p "$OUT_DIR"
chown loopsign:loopsign "$OUT_DIR"

write_value() {
  local file="$1"
  local value="$2"
  printf '%s\n' "$value" > "$OUT_DIR/$file"
  chown loopsign:loopsign "$OUT_DIR/$file"
}

sanitize() {
  echo "$1" | tr '\n\r' ' ' | sed 's/[;()]/_/g' | xargs
}

CPU_MODEL="$(lscpu | awk -F: '/Model name/ {gsub(/^[ \t]+/, "", $2); print $2; exit}')"
RAM_TOTAL="$(free -h | awk '/Mem:/ {print $2}')"
STORAGE_TOTAL="$(df -h / | awk 'NR==2 {print $2}')"
FIREFOX_VERSION="$(firefox-esr --version 2>/dev/null | sed 's/Mozilla Firefox //')"

# X11 display probing
export DISPLAY="${DISPLAY:-:0.0}"
export XAUTHORITY="${XAUTHORITY:-/home/loopsign/.Xauthority}"

XRANDR_OUTPUT="$(xrandr --query 2>/dev/null || true)"
XRANDR_PROPS="$(xrandr --props 2>/dev/null || true)"

DISPLAY_OUTPUT="$(echo "$XRANDR_OUTPUT" | awk '/ connected/ {print $1; exit}')"

CURRENT_MODE_LINE="$(
  echo "$XRANDR_OUTPUT" | awk '
    / connected/ {in_display=1; next}
    in_display && /\*/ {print; exit}
  '
)"

DISPLAY_RESOLUTION="$(echo "$CURRENT_MODE_LINE" | awk '{print $1}')"
DISPLAY_REFRESH="$(echo "$CURRENT_MODE_LINE" | grep -oE '[0-9]+(\.[0-9]+)?\*' | tr -d '*' | head -n1)"

DISPLAY_NAME="$(
  echo "$XRANDR_PROPS" | awk -v output="$DISPLAY_OUTPUT" '
    $1 == output {in_output=1; next}
    in_output && /^[^[:space:]]/ {exit}
    in_output && /EDID:/ {edid=1; next}
    edid && /^[[:space:]]+[0-9a-fA-F]+/ {
      gsub(/[[:space:]]/, "", $0)
      printf "%s", $0
    }
  ' | grep -oE '000000fc00[0-9a-fA-F]{26}' \
    | head -n1 \
    | sed 's/^000000fc00//' \
    | xxd -r -p 2>/dev/null \
    | tr -d '\000\n\r' \
    | xargs
)"

CPU_MODEL="$(sanitize "$CPU_MODEL")"
RAM_TOTAL="$(sanitize "$RAM_TOTAL")"
STORAGE_TOTAL="$(sanitize "$STORAGE_TOTAL")"
FIREFOX_VERSION="$(sanitize "$FIREFOX_VERSION")"
DISPLAY_NAME="$(sanitize "$DISPLAY_NAME")"
DISPLAY_OUTPUT="$(sanitize "$DISPLAY_OUTPUT")"
DISPLAY_RESOLUTION="$(sanitize "$DISPLAY_RESOLUTION")"
DISPLAY_REFRESH="$(sanitize "$DISPLAY_REFRESH")"

write_value "cpu_model" "${CPU_MODEL:-unknown}"
write_value "ram_total" "${RAM_TOTAL:-unknown}"
write_value "storage_total" "${STORAGE_TOTAL:-unknown}"
write_value "firefox_version" "${FIREFOX_VERSION:-unknown}"
write_value "display_output" "${DISPLAY_OUTPUT:-unknown}"
write_value "display_name" "${DISPLAY_NAME:-unknown}"
write_value "display_resolution" "${DISPLAY_RESOLUTION:-unknown}"
write_value "display_refresh" "${DISPLAY_REFRESH:-unknown}"

USER_AGENT="Mozilla/5.0 (X11; Linux x86_64; rv:${FIREFOX_VERSION:-unknown}) Gecko/20100101 Firefox/${FIREFOX_VERSION:-unknown} LoopSignPlayer/1.0 Platform=${CPU_MODEL:-unknown}; RAM=${RAM_TOTAL:-unknown}; Storage=${STORAGE_TOTAL:-unknown}; Display=${DISPLAY_NAME:-unknown}; Resolution=${DISPLAY_RESOLUTION:-unknown}; Refresh=${DISPLAY_REFRESH:-unknown}Hz"

write_value "user_agent" "$USER_AGENT"

echo "Generated player info:"
cat "$OUT_DIR/user_agent"
