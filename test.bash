#!/bin/bash

# https://disconnected.systems/blog/raspberry-pi-archlinuxarm-setup/

# Fail on error
set -euo pipefail

# Print each command
set -o xtrace

# Update and install qemu packages
# sudo apt update
# sudo apt install -y qemu-user-static

# =======================================================================
# Device Setup
# =======================================================================


# Detach loopback in case earlier runs have been interrupted
sudo losetup --detach "/dev/loop0" || true

# Unmount loopback partitionos
sudo umount /mnt/boot || true
sudo umount /mnt || true


# Make a file full of zeros
fallocate -l 4G "custom-pi.img"

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


sudo arch-chroot /mnt /usr/bin/bash <<"EOT"

set -euo pipefail


# Pacman Keyring
pacman-key --init 
pacman-key --populate archlinuxarm

# vim and bash completion
pacman -Syyu --noconfirm vim bash-completion sudo base-devel git go

# Set hostname to starport-pi
echo starport-pi > /etc/hostname


# make alarm "pi" with password "pi"
sed -i "s/alarm/pi/g" /etc/passwd /etc/group /etc/shadow
mv /home/alarm "/home/pi"
echo -e "secret\nsecret" | passwd "pi"


# Builduser and yay
useradd builduser -m 
passwd -d builduser 
printf 'builduser ALL=(ALL) ALL\n' | tee -a /etc/sudoers 		
sudo -u builduser bash -c 'cd ~/ && git clone https://aur.archlinux.org/yay.git yay && cd yay && makepkg -s --noconfirm'


# starport-pi.local mdns
pacman -S --noconfirm avahi nss-mdns
sed -i '/^hosts: /s/files dns/files mdns dns/' /etc/nsswitch.conf
ln -sf /usr/lib/systemd/system/avahi-daemon.service /etc/systemd/system/multi-user.target.wants/avahi-daemon.service



EOT


#=========================================================================
# Cleanup
#========================================================================

# Restore resolv.conf to original form
sudo rm /mnt/etc/resolv.conf
sudo mv /mnt/etc/resolv.conf.bak /mnt/etc/resolv.conf

# Remove qemu-arm-static
sudo rm /mnt/usr/bin/qemu-arm-static

# Detach loop-mouted disk
sudo losetup --detach "/dev/loop0"
