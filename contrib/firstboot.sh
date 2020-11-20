#!/bin/bash

rm -f /etc/ssh/ssh_host_*
ssh-keygen -v -A

# There is no longer a /dev/mmcblk0p3
# umount /dev/mmcblk0p3
# parted /dev/mmcblk0 -a optimal -s resizepart 3 100%
# yes | mkfs.ext4 -F -m 0 /dev/mmcblk0p3
# mount /dev/mmcblk0p3

# Set Time Zone
# Later, make this automatic based on location.
timedatectl set-timezone UTC

# mdns
systemd-resolve --set-mdns=yes --interface=eth0

# Don't run again
systemctl disable pikvm-firstboot
