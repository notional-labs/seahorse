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

# Unmount loopback partitionos
sudo umount /spos/boot || true
sudo umount /spos || true

# Detach loopback in case earlier runs have been interrupted
sudo losetup --detach "/dev/loop0" || true

# Remove /spos for hygene.  Make new /spos
rm -rf /spos
mkdir /spos || true

# Make a file full of zeros
fallocate -l 4G "starport-pi.img"

# Create the looopback device
sudo losetup --find --show "starport-pi.img"

# Partition the loop-mounted disk
sudo parted --script /dev/loop0 mklabel msdos
sudo parted --script /dev/loop0 mkpart primary fat32 0% 200M
sudo parted --script /dev/loop0 mkpart primary ext4 200M 100%

# Format the loop-mounted disk.
sudo mkfs.vfat -F32 /dev/loop0p1
sudo mkfs.ext4 -F /dev/loop0p2

# Mounting the loopback device
sudo mount /dev/loop0p2 /spos
sudo mkdir /spos/boot
sudo mount /dev/loop0p1 /spos/boot

# Download root filesystem
wget -N --progress=bar:force:noscroll http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz
sudo tar -xpf "ArchLinuxARM-rpi-aarch64-latest.tar.gz" -C /spos
sudo cp /usr/bin/qemu-arm-static /spos/usr/bin/

# Remove empty kernel module arrray
sed -e s/"MODULES=()"//g /spos/etc/mkinitcpio.conf

# Add needed kernel modules for networking

echo "MODULES=(bcm_phy_lib broadcom mdio_bcm_unimac genet)" >> /etc/mkinitcpio.conf

# Use host resolv.conf
sudo mv /spos/etc/resolv.conf /spos/etc/resolv.conf.bak
sudo cp /etc/resolv.conf /spos/etc/resolv.conf



# =======================================================================
# Run in chroot
# We Install the OS in a chroot
# =======================================================================


sudo arch-chroot /spos /usr/bin/bash <<"EOT"

# fail on error
set -euo pipefail

# Pacman Keyring
pacman-key --init 
pacman-key --populate archlinuxarm

# vim and bash completion
pacman -Syyu --noconfirm vim bash-completion sudo base-devel git go go-ipfs npm yarn

# Set hostname to starport-pi
echo starport-pi > /etc/hostname

# Enable mdns
echo "MulticastDNS=true" >> /etc/systemd/network/en*
echo "MulticastDNS=true" >> /etc/systemd/network/et*

# make alarm "pi" with password "pi"
sed -i "s/alarm/pi/g" /etc/passwd /etc/group /etc/shadow
mv /home/alarm "/home/pi"
echo -e "secret\nsecret" | passwd "pi"

# Builduser
useradd builduser -m 
passwd -d builduser 
printf 'builduser ALL=(ALL) ALL\n' | tee -a /etc/sudoers 		

# Yay AUR manager
sudo -u builduser bash -c 'cd ~/ && git clone https://aur.archlinux.org/yay.git yay && cd yay && makepkg -s --noconfirm'

# Systemd-networkd
systemctl enable systemd-networkd
systemctl enable systemd-resolved

# starport-pi.local mdns
# pacman -S --noconfirm avahi nss-mdns
# sed -i '/^hosts: /s/files dns/files mdns dns/' /etc/nsswitch.conf
# ln -sf /usr/lib/systemd/system/avahi-daemon.service /etc/systemd/system/multi-user.target.wants/avahi-daemon.service

EOT


#=========================================================================
# Cleanup
#========================================================================

# Restore resolv.conf to original form
sudo rm /spos/etc/resolv.conf
sudo mv /spos/etc/resolv.conf.bak /spos/etc/resolv.conf

# Remove qemu-arm-static
sudo rm /spos/usr/bin/qemu-arm-static

# Detach loop-mouted disk
sudo losetup --detach "/dev/loop0"
