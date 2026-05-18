#!/bin/bash

exec > /tmp/autorun.log 2>&1
echo "autorun.sh started at $(date)"

REPO_DIR="/home/loopsign/ls-x86intel"
CONFIG_FILE="/home/loopsign/config"
BRANCH="prod"
GITHUB_REPO_URL="https://github.com/Loop24-AS/ls-x86intel.git"
CURRENT_SCRIPT_PATH="/home/loopsign/autorun.sh"
NEW_SCRIPT_PATH="$REPO_DIR/autorun.sh"

check_time_sync() {
    local displayed=false

    while true; do
        if timedatectl show -p NTPSynchronized --value | grep -q "yes"; then
            echo "System time is synchronized."
            break
        fi

        if [ "$displayed" = false ]; then
            echo "Waiting for time sync."
            zenity --info --text="Your LoopSign screen will start once a working internet connection is established and the player's time and date have been synced.

Please note that this might take a couple of minutes.

If your LoopSign screen won't start, please check your network and/or NTP settings." &
            displayed=true
        fi

        sleep 1
    done
}

update_repository() {
    if [ -f "$CONFIG_FILE" ]; then
        BRANCH="$(tr -d '[:space:]' < "$CONFIG_FILE")"
        [ -z "$BRANCH" ] && BRANCH="prod"
    else
        echo "prod" > "$CONFIG_FILE"
        BRANCH="prod"
    fi

    if [ ! -d "$REPO_DIR/.git" ]; then
        echo "Repository not found at $REPO_DIR"
        exit 1
    fi

    cd "$REPO_DIR" || exit 1

    git remote set-url origin "$GITHUB_REPO_URL"
    git fetch origin "$BRANCH"
    git reset --hard "origin/$BRANCH"

    echo "Repository updated to branch: $BRANCH"
}

self_update_if_needed() {
    if [ ! -f "$NEW_SCRIPT_PATH" ]; then
        echo "No autorun.sh found in repo."
        return
    fi

    if ! cmp -s "$NEW_SCRIPT_PATH" "$CURRENT_SCRIPT_PATH"; then
        echo "New autorun.sh detected. Replacing current script and restarting."

        cat > /home/loopsign/update_autorun_and_restart.sh <<EOF
#!/bin/bash
sleep 2
cp "$NEW_SCRIPT_PATH" "$CURRENT_SCRIPT_PATH"
chmod +x "$CURRENT_SCRIPT_PATH"
exec "$CURRENT_SCRIPT_PATH"
EOF

        chmod +x /home/loopsign/update_autorun_and_restart.sh
        nohup /home/loopsign/update_autorun_and_restart.sh >/dev/null 2>&1 &
        exit 0
    fi

    echo "autorun.sh is already up to date."
}

start_countdown() {
    (
        for i in {10..1}; do
            echo "# Your LoopSign screen will launch in about $i seconds..."
            echo "$(( (10 - i + 1) * 10 ))"
            sleep 1
        done
        echo "100"
    ) | zenity --progress \
        --title="LoopSign" \
        --text="Please wait..." \
        --percentage=0 \
        --auto-close \
        --no-cancel &
}

# Hide mouse cursor on X11
unclutter -idle 1 -root &

check_time_sync
update_repository
self_update_if_needed

# Make all scripts in repo directory executable
find "$REPO_DIR" -type f -name "*.sh" -exec chmod +x {} \;

pkill zenity 2>/dev/null

sudo "$REPO_DIR/define-sudo-crontab.sh"

sudo "$REPO_DIR/generate-player-info.sh"

sudo "$REPO_DIR/setup-firefox-config.sh"

"$REPO_DIR/hashgenerator.sh"

start_countdown

cd "$REPO_DIR" || exit 1

nohup ./autorefresh.sh >/tmp/autorefresh-launch.log 2>&1 &
nohup ./cache-refresh.sh &
exec ./loopsign.sh
