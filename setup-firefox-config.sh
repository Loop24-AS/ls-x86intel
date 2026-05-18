#!/bin/bash
set -e

REPO_DIR="/home/loopsign/ls-x86intel"
USER_AGENT_FILE="/home/loopsign/player-info/user_agent"
CFG_TEMPLATE="$REPO_DIR/firefox/loopsign.cfg"
CFG_TARGET="/usr/lib/firefox-esr/loopsign.cfg"

echo "Installing Firefox ESR enterprise policies and AutoConfig..."

sudo mkdir -p /usr/lib/firefox-esr/distribution
sudo mkdir -p /usr/lib/firefox-esr/defaults/pref

sudo install -m 644 "$REPO_DIR/firefox/policies.json" \
  /usr/lib/firefox-esr/distribution/policies.json

sudo install -m 644 "$REPO_DIR/firefox/autoconfig.js" \
  /usr/lib/firefox-esr/defaults/pref/autoconfig.js

sudo install -m 644 "$CFG_TEMPLATE" "$CFG_TARGET"

if [ -s "$USER_AGENT_FILE" ]; then
  USER_AGENT="$(sed 's/\\/\\\\/g; s/"/\\"/g' "$USER_AGENT_FILE")"

  sudo sed -i '/general\.useragent\.override/d' "$CFG_TARGET"

  echo "lockPref(\"general.useragent.override\", \"$USER_AGENT\");" | \
    sudo tee -a "$CFG_TARGET" >/dev/null

  echo "Applied dynamic Firefox user agent."
else
  echo "Warning: $USER_AGENT_FILE not found or empty. User agent not updated."
fi

echo "Done."
