#!/bin/bash

# Generate a stable 7-character hash based on the machine's ethernet MAC address.
# On x86, the interface name is typically enp*s* or eth0 — we detect it dynamically.

HASH_FILE="/home/loopsign/Desktop/.hash.txt"

# Find the first active non-loopback ethernet interface
IFACE=$(ip -o link show | awk -F': ' '$2 !~ /lo|vir|docker|br-|veth/ {print $2; exit}')

if [ -z "$IFACE" ]; then
    echo "No suitable network interface found. Cannot generate hash."
    exit 1
fi

MAC=$(cat /sys/class/net/"$IFACE"/address 2>/dev/null)

if [ -z "$MAC" ]; then
    echo "Could not read MAC address for interface $IFACE."
    exit 1
fi

# Generate a 7-character alphanumeric hash from the MAC
HASH=$(echo "$MAC" | sha256sum | tr -dc 'a-z0-9' | head -c 7 | tr '[:lower:]' '[:upper:]')

echo "Interface: $IFACE | MAC: $MAC | Hash: $HASH"

# Write hash to Desktop (hidden file, consistent with original)
mkdir -p /home/loopsign/Desktop
echo "$HASH" > "$HASH_FILE"

echo "Hash written to $HASH_FILE"
