#!/bin/bash
set -e

REPO_DIR="/home/loopsign/ls-x86intel"

echo "Installing Firefox ESR enterprise policies and AutoConfig..."

sudo mkdir -p /usr/lib/firefox-esr/distribution
sudo mkdir -p /usr/lib/firefox-esr/defaults/pref

sudo install -m 644 "$REPO_DIR/firefox/policies.json" \
  /usr/lib/firefox-esr/distribution/policies.json

sudo install -m 644 "$REPO_DIR/firefox/autoconfig.js" \
  /usr/lib/firefox-esr/defaults/pref/autoconfig.js

sudo install -m 644 "$REPO_DIR/firefox/loopsign.cfg" \
  /usr/lib/firefox-esr/loopsign.cfg

echo "Done."
