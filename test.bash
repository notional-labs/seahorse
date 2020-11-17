#!/bin/bash

# https://disconnected.systems/blog/raspberry-pi-archlinuxarm-setup/

# Fail on error
set -euo pipefail

# Print each command
set -o xtrace

# Update and install qemu packages
sudo apt update
sudo apt install -y qemu-user-static

# =======================================================================
# Device Setup
# =======================================================================

# Make a file full of zeros
fallocate -l 2G "custom-pi.img"


# Detach loopback in case earlier runs have been interrupted
sudo losetup --detach "/dev/loop0" || true


# Create the looopback device
sudo losetup --find --show "custom-pi.img"

# Partition the loop-mounted disk
sudo parted --script /dev/loop0 mklabel msdos
sudo parted --script /dev/loop0 mkpart primary fat32 0% 200M
sudo parted --script /dev/loop0 mkpart primary ext4 200M 100%

# Format the loop-mounted disk.
sudo mkfs.vfat -F32 /dev/loop0p1
sudo mkfs.ext4 -F /dev/loop0p2

# Mounting the loopback device
sudo mount /dev/loop0p2 /mnt
sudo mkdir /mnt/boot
sudo mount /dev/loop0p1 /mnt/boot


# Download root filesystem
wget -N --progress=bar:force:noscroll http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz
sudo tar -xpf "ArchLinuxARM-rpi-aarch64-latest.tar.gz" -C /mnt
sudo cp /usr/bin/qemu-arm-static /mnt/usr/bin/

# Use host resolv.conf
sudo mv /mnt/etc/resolv.conf /mnt/etc/resolv.conf.bak
sudo cp /etc/resolv.conf /mnt/etc/resolv.conf


# =======================================================================
# Run in chroot
# =======================================================================

ls /mnt/usr/bin/ba*


sudo chroot /mnt /usr/bin/bash <<"EOT"

set -euo pipefail

pacman -Syyu vim bash-completion
echo starport-pi > /etc/hostname

sed -i "s/alarm/pi/g" /etc/passwd /etc/group /etc/shadow
mv /home/alarm "/home/pi"
echo -e "secret\nsecret" | passwd "pi"

pacman -S --noconfirm avahi nss-mdns
sed -i '/^hosts: /s/files dns/files mdns dns/' /etc/nsswitch.conf
ln -sf /usr/lib/systemd/system/avahi-daemon.service /etc/systemd/system/multi-user.target.wants/avahi-daemon.service

sed -i 's/mmcblk0/mmcblk1/g' root/etc/fstab

# Unmount devices
sudo umount /mnt/dev
sudo umount /mnt/proc
sudo umount /mnt/sys

EOT

# Restore resolv.conf to original form
sudo rm /mnt/etc/resolv.conf
sudo mv /mnt/etc/resolv.conf.bak /mnt/etc/resolv.conf

# Remove qemu-arm-static
sudo rm /mnt/usr/bin/qemu-arm-static

# Unmount loopback partitionos
sudo umount /mnt/boot
sudo umount /mnt

# Detach loop-mouted disk
sudo losetup --detach "/dev/loop0"
