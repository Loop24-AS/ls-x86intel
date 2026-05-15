#!/bin/bash

set -u

OUTPUT_FILE="/home/loopsign/Desktop/.hash.txt"
LOG_FILE="/tmp/hashgenerator.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

clean_value() {
    echo "$1" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]'
}

is_valid_mac() {
    case "$1" in
        ""|"00:00:00:00:00:00"|"ff:ff:ff:ff:ff:ff")
            return 1
            ;;
    esac

    echo "$1" | grep -Eq '^[0-9a-f]{2}(:[0-9a-f]{2}){5}$'
}

get_ethernet_mac() {
    for iface_path in /sys/class/net/*; do
        iface="$(basename "$iface_path")"

        [ "$iface" = "lo" ] && continue
        [ ! -f "$iface_path/address" ] && continue

        mac="$(clean_value "$(cat "$iface_path/address")")"

        if ! is_valid_mac "$mac"; then
            continue
        fi

        # Prefer Ethernet-style interfaces only.
        case "$iface" in
            eth*|en*)
                echo "$mac"
                return 0
                ;;
        esac
    done

    return 1
}

get_machine_id() {
    if [ -s /etc/machine-id ]; then
        clean_value "$(cat /etc/machine-id)"
        return 0
    fi

    return 1
}

get_dmi_value() {
    local file="$1"

    if [ -r "$file" ]; then
        value="$(clean_value "$(cat "$file")")"

        case "$value" in
            ""|"none"|"unknown"|"notapplicable"|"notavailable"|"tobefilledbyo.e.m."|"defaultstring"|"systemserialnumber")
                return 1
                ;;
            *)
                echo "$value"
                return 0
                ;;
        esac
    fi

    return 1
}

get_disk_serial() {
    for disk in /dev/disk/by-id/*; do
        [ -e "$disk" ] || continue

        base="$(basename "$disk")"

        case "$base" in
            *-part*|wwn-*)
                continue
                ;;
        esac

        value="$(clean_value "$base")"

        if [ -n "$value" ]; then
            echo "$value"
            return 0
        fi
    done

    return 1
}

make_hash() {
    local source_type="$1"
    local source_value="$2"

    printf '%s:%s' "$source_type" "$source_value" | sha256sum | awk '{print toupper(substr($1,1,7))}'
}

mkdir -p "$(dirname "$OUTPUT_FILE")"

log "Starting hash generation."

if value="$(get_ethernet_mac)"; then
    source_type="ethernet-mac"
    source_value="$value"
elif value="$(get_machine_id)"; then
    source_type="machine-id"
    source_value="$value"
elif value="$(get_dmi_value /sys/class/dmi/id/product_uuid)"; then
    source_type="product-uuid"
    source_value="$value"
elif value="$(get_dmi_value /sys/class/dmi/id/product_serial)"; then
    source_type="product-serial"
    source_value="$value"
elif value="$(get_dmi_value /sys/class/dmi/id/board_serial)"; then
    source_type="board-serial"
    source_value="$value"
elif value="$(get_disk_serial)"; then
    source_type="disk-serial"
    source_value="$value"
else
    log "ERROR: Could not find any usable static device identifier."
    exit 1
fi

hash="$(make_hash "$source_type" "$source_value")"

echo "$hash" > "$OUTPUT_FILE"

log "Hash generated: $hash"
log "Source type: $source_type"
log "Output written to: $OUTPUT_FILE"#!/bin/bash

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
