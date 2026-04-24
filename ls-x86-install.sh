#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/Loop24-AS/ls-x86xubuntu.git"
BRANCH="prod"

LOOPSIGN_USER="loopsign"
LOOPSIGN_HOME="/home/$LOOPSIGN_USER"
REPO_DIR="$LOOPSIGN_HOME/ls-x86xubuntu"

echo "LoopSign x86/Xubuntu installer"
echo "================================"

if [[ "$(id -un)" != "$LOOPSIGN_USER" ]]; then
  echo "Error: Run this script as the '$LOOPSIGN_USER' user."
  echo "Current user: $(id -un)"
  exit 1
fi

sudo -v

echo "Installing required packages..."

sudo apt update

sudo apt install -y \
  ca-certificates \
  curl \
  wget \
  gnupg \
  git \
  xdotool \
  unclutter \
  zenity \
  vainfo \
  mesa-va-drivers \
  intel-media-va-driver \
  i965-va-driver-shaders \
  intel-gpu-tools \
  fonts-noto-color-emoji \
  plymouth \
  plymouth-themes \
  xfconf

echo "Installing Firefox from Mozilla APT repository..."

sudo install -d -m 0755 /etc/apt/keyrings

wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- \
  | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc >/dev/null

cat <<EOF | sudo tee /etc/apt/sources.list.d/mozilla.list >/dev/null
deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main
EOF

cat <<EOF | sudo tee /etc/apt/preferences.d/mozilla >/dev/null
Package: firefox*
Pin: origin packages.mozilla.org
Pin-Priority: 1001
EOF

sudo snap remove firefox >/dev/null 2>&1 || true
sudo apt remove -y firefox >/dev/null 2>&1 || true

sudo apt update
sudo apt install -y firefox

echo "Cloning/updating repo..."

if [[ -d "$REPO_DIR/.git" ]]; then
  git -C "$REPO_DIR" fetch origin "$BRANCH"
  git -C "$REPO_DIR" checkout "$BRANCH"
  git -C "$REPO_DIR" pull --ff-only
else
  git clone --branch "$BRANCH" "$REPO_URL" "$REPO_DIR"
fi

chmod +x "$REPO_DIR"/*.sh || true

echo "Installing autorun..."

cp "$REPO_DIR/autorun.sh" "$LOOPSIGN_HOME/autorun.sh"
chmod +x "$LOOPSIGN_HOME/autorun.sh"

mkdir -p "$LOOPSIGN_HOME/.config/autostart"

cp "$REPO_DIR/loopsign-autorun.desktop" \
  "$LOOPSIGN_HOME/.config/autostart/loopsign-autorun.desktop"

echo "Configuring Firefox profile..."

FIREFOX_PROFILE_DIR="$LOOPSIGN_HOME/.mozilla/firefox/loopsign.default"
mkdir -p "$FIREFOX_PROFILE_DIR"

firefox -CreateProfile "loopsign $FIREFOX_PROFILE_DIR" >/dev/null 2>&1 || true

cat > "$FIREFOX_PROFILE_DIR/user.js" <<'EOF'
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.tabs.warnOnClose", false);
user_pref("browser.tabs.warnOnCloseOtherTabs", false);
user_pref("browser.sessionstore.resume_from_crash", false);
user_pref("browser.startup.homepage_override.mstone", "ignore");
user_pref("browser.aboutwelcome.enabled", false);
user_pref("browser.rights.3.shown", true);

user_pref("dom.webnotifications.enabled", false);
user_pref("permissions.default.desktop-notification", 2);

user_pref("media.ffmpeg.vaapi.enabled", true);
user_pref("media.hardware-video-decoding.force-enabled", true);
user_pref("media.rdd-vpx.enabled", false);

user_pref("media.autoplay.default", 0);
user_pref("media.autoplay.blocking_policy", 0);
user_pref("media.autoplay.allow-muted", true);
user_pref("media.block-autoplay-until-in-foreground", false);

user_pref("full-screen-api.warning.timeout", 0);
user_pref("full-screen-api.transition-duration.enter", "0 0");
user_pref("full-screen-api.transition-duration.leave", "0 0");
EOF

echo "Disabling screen blanking/power saving..."

xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -n -t int -s 0 2>/dev/null || true
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled -n -t bool -s false 2>/dev/null || true
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/inactivity-on-ac -n -t int -s 14 2>/dev/null || true

xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true

echo "Installing sudo crontab..."

"$REPO_DIR/define-sudo-crontab.sh" || true

echo
echo "Installation complete."
echo
echo "Recommended checks:"
echo "  vainfo"
echo "  firefox -P loopsign --kiosk https://play.loopsign.eu"
echo "  sudo intel_gpu_top"
echo
echo "Reboot recommended."
