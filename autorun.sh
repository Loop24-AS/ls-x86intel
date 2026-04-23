#!/bin/bash

exec > /tmp/autorun.log 2>&1

echo "Script started at $(date)"

# Function to check internet connection and time sync
check_internet_and_time_sync() {
    synced=false
    displayed=false

    while true; do
        if timedatectl show -p NTPSynchronized --value | grep -q "yes"; then
            synced=true
            echo "System time has been synchronized."
            break
        fi

        if ! $synced && ! $displayed; then
            echo "Displaying initial zenity message about time sync."
            zenity --info --text="Your LoopSign screen will start once a working internet connection is established and the player's time and date have been synced. Please note that this might take a couple of minutes. If your LoopSign screen won't start, please check your network and/or NTP settings." &
            displayed=true
        fi

        sleep 1
    done
}

# Function to update the repository
update_repository() {
    local REPO_DIR="/home/loopsign/ls-x86ubuntu"
    local CONFIG_FILE="/home/loopsign/config"
    local BRANCH="prod"
    local GITHUB_REPO_URL="https://github.com/Loop23-AS/ls-x86xubuntu.git"  # <-- update this

    if [ -f "$CONFIG_FILE" ]; then
        BRANCH=$(cat "$CONFIG_FILE" | tr -d '[:space:]')
        if [ -z "$BRANCH" ]; then
            echo "Config file is empty. Defaulting to 'prod'."
            BRANCH="prod"
        fi
    else
        echo "Config file does not exist. Creating it with the default branch 'prod'."
        echo "prod" > "$CONFIG_FILE"
    fi

    if [ -d "$REPO_DIR/.git" ]; then
        cd "$REPO_DIR"
        git remote set-url origin "$GITHUB_REPO_URL"
        echo "Fetching latest changes..."
        git fetch origin
        echo "Resetting local branch to match remote..."
        git reset --hard origin/$BRANCH
        echo "Repository updated to branch $BRANCH."
    else
        echo "Repository directory does not exist or is not a git repo. Exiting."
        exit 1
    fi
}

# Function to check for and apply autorun.sh updates
schedule_master_script_update_and_restart() {
    NEW_SCRIPT_PATH="/home/loopsign/ls-x86xubuntu/autorun.sh"
    CURRENT_SCRIPT_PATH="/home/loopsign/autorun.sh"

    if [ -f "$NEW_SCRIPT_PATH" ]; then
        NEW_HASH=$(sha256sum "$NEW_SCRIPT_PATH" | awk '{print $1}')
        CURRENT_HASH=$(sha256sum "$CURRENT_SCRIPT_PATH" | awk '{print $1}')

        if [ "$NEW_HASH" != "$CURRENT_HASH" ]; then
            echo "New version of autorun.sh detected. Scheduling update and restart..."

            cat <<EOF > /home/loopsign/update_and_restart.sh
#!/bin/bash
sleep 2
mv "$NEW_SCRIPT_PATH" "$CURRENT_SCRIPT_PATH"
chmod +x "$CURRENT_SCRIPT_PATH"
/bin/bash "$CURRENT_SCRIPT_PATH"
rm -- "\$0"
EOF
            chmod +x /home/loopsign/update_and_restart.sh
            nohup /home/loopsign/update_and_restart.sh > /dev/null 2>&1 &
            exit 0
        else
            echo "autorun.sh is already up to date."
        fi
    else
        echo "No new autorun.sh found in repository."
    fi
}

# Countdown dialog while secondary scripts initialise
start_countdown() {
    (
        for i in {10..1}; do
            echo "# Your LoopSign screen will launch in about $i seconds..."
            echo "$(( (10 - i + 1) * 10 ))"
            sleep 1
        done
        echo "100"
    ) | zenity --progress \
        --title="Countdown" \
        --text="Please wait..." \
        --percentage=0 \
        --auto-close \
        --no-cancel &
}

# --- Main sequence ---

# Hide cursor using unclutter (X11 approach, replaces udevmon/hideaway)
unclutter -idle 0 -root &

# Wait for NTP sync
check_internet_and_time_sync

# Pull latest repo changes
update_repository

# Apply autorun.sh update if needed
schedule_master_script_update_and_restart

# Dismiss any leftover zenity dialogs
pkill zenity

# Set cron jobs
chmod +x /home/loopsign/ls-x86xubuntu/define-sudo-crontab.sh
sudo /home/loopsign/ls-x86xubuntu/define-sudo-crontab.sh

# Generate device hash
chmod +x /home/loopsign/ls-x86xubuntu/hashgenerator.sh
/home/loopsign/ls-x86xubuntu/hashgenerator.sh

# Show countdown
start_countdown

# Launch secondary scripts
cd /home/loopsign/ls-x86xubuntu
chmod +x autorefresh.sh loopsign.sh

nohup ./autorefresh.sh &
./loopsign.sh &
