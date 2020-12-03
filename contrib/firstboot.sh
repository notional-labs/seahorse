#!/bin/bash

# Set Time Zone
# Later, make this automatic based on location.
timedatectl set-timezone UTC

# mdns
systemd-resolve --set-mdns=yes --interface=eth0

# install go and npm
pacman -Syyu --noconfirm npm go

# Don't run again
systemctl disable firstboot
