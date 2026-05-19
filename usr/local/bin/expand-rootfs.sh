#!/bin/bash
set -e

MARKER="/var/lib/loopsign/rootfs-expanded"

if [ -f "$MARKER" ]; then
    exit 0
fi

mkdir -p /var/lib/loopsign

ROOT_PART="$(findmnt -n -o SOURCE /)"
DISK="/dev/$(lsblk -no PKNAME "$ROOT_PART")"
PARTNUM="$(lsblk -no PARTN "$ROOT_PART")"

echo "Root partition: $ROOT_PART"
echo "Disk: $DISK"
echo "Partition number: $PARTNUM"

growpart "$DISK" "$PARTNUM"
resize2fs "$ROOT_PART"

touch "$MARKER"

systemctl disable loopsign-expand-rootfs.service || true

echo "Root filesystem expansion complete."

sleep 1

reboot
