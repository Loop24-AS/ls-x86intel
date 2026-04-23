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
HASH=$(echo "$MAC" | sha256sum | tr -dc 'a-z0-9' | head -c 7)

echo "Interface: $IFACE | MAC: $MAC | Hash: $HASH"

# Write hash to Desktop (hidden file, consistent with original)
mkdir -p /home/loopsign/Desktop
echo "$HASH" > "$HASH_FILE"

echo "Hash written to $HASH_FILE"#!/bin/bash

# Step 1: Read MAC address and remove colons
mac=$(cat /sys/class/net/eth0/address | tr -d ':')

# Step 2: Hash MAC address using SHA-256
hashed_mac=$(echo -n "$mac" | sha256sum | cut -d ' ' -f1)

# Step 3: Encode hashed MAC address using Base64
encoded_mac=$(echo -n "$hashed_mac" | base64)

# Step 4: Hash encoded MAC address using SHA-256 again and remove characters 1, I, O, and 0
hashed_encoded_mac=$(echo -n "$encoded_mac" | sha256sum | tr -d '1IO0 ')

# Step 5: Select the first 7 characters of the hashed result and convert lowercase letters to uppercase
code=$(echo -n "${hashed_encoded_mac:0:7}" | tr '[:lower:]' '[:upper:]')

# Step 6: Create a hidden text file on the desktop with the resulting 7-character code
echo "$code" > /home/loopsign/Desktop/.hash.txt
