#!/bin/bash

ROOT_PART=$(findmnt / -o SOURCE -n)
DISK=$(lsblk -no pkname "$ROOT_PART")
PARTNUM=$(echo "$ROOT_PART" | grep -o '[0-9]*$')

growpart /dev/$DISK $PARTNUM
resize2fs $ROOT_PART

systemctl disable expand-rootfs.service
rm -f /etc/systemd/system/expand-rootfs.service

reboot
