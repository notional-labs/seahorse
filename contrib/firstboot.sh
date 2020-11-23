#!/bin/bash

rm -f /etc/ssh/ssh_host_*

# Set Time Zone
# Later, make this automatic based on location.
timedatectl set-timezone UTC

# mdns
systemd-resolve --set-mdns=yes --interface=eth0

# Don't run again
systemctl disable pikvm-firstboot
