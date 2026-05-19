#!/bin/bash
set -e

echo "Cleaning apt cache..."
apt clean
apt autoclean
apt autoremove -y

echo "Removing logs..."
journalctl --vacuum-time=1s || true
find /var/log -type f -delete
find /var/log -type d -empty -delete
mkdir -p /var/log/journal

echo "Removing temp files..."
rm -rf /tmp/*
rm -rf /var/tmp/*

echo "Removing user cache..."
rm -rf /home/loopsign/.cache/*
rm -rf /root/.cache/*

echo "Removing browser cache..."
rm -rf /home/loopsign/.cache/mozilla/firefox/*
rm -rf /home/loopsign/.mozilla/firefox/*.default*/cache2
rm -rf /home/loopsign/.mozilla/firefox/*.default*/startupCache

echo "Removing thumbnails..."
rm -rf /home/loopsign/.thumbnails/*

echo "Removing SSH host keys..."
rm -f /etc/ssh/ssh_host_*

echo "Resetting machine-id..."
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id

echo "Clearing shell history..."
history -c || true
rm -f /home/loopsign/.bash_history
rm -f /root/.bash_history

echo "Removing NetworkManager temp state..."
rm -f /var/lib/NetworkManager/NetworkManager.state

echo "Syncing..."
sync

echo "DONE."
