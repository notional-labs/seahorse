#!/bin/bash

# https://disconnected.systems/blog/raspberry-pi-archlinuxarm-setup/

# Fail on error
set -euo pipefail

# Update and install qemu packages
sudo apt update
sudo apt install -y qemu-user-static

# =======================================================================
# Device Setup
# =======================================================================


fallocate -l 2G "custom-pi.img"


export device=$(sudo losetup --find --show "custom-pi.img")


sudo parted --script /dev/loop0 mklabel msdos
sudo parted --script /dev/loop0 mkpart primary fat32 0% 200M
sudo parted --script /dev/loop0 mkpart primary ext4 200M 100%
sudo mkfs.vfat -F32 /dev/loop0p1
sudo mkfs.ext4 -F /dev/loop0p2
sudo mount /dev/loop0p2 /mnt
sudo mkdir /mnt/boot
sudo mount /dev/loop0p1 /mnt/boot

wget -N --progress=bar:force:noscroll http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz
sudo tar -xpf "ArchLinuxARM-rpi-aarch64-latest.tar.gz" -C /mnt
sudo cp /usr/bin/qemu-arm-static /mnt/usr/bin/



# =======================================================================
# Run in chroot
# =======================================================================



sudo chroot /mnt /bin/bash <<"EOT"

pacman -Syyu vim bash-completion
echo starport-pi > /etc/hostname

sed -i "s/alarm/pi/g" /etc/passwd /etc/group /etc/shadow
mv /home/alarm "/home/pi"
echo -e "secret\nsecret" | passwd "pi"

pacman -S --noconfirm avahi nss-mdns
sed -i '/^hosts: /s/files dns/files mdns dns/' /etc/nsswitch.conf
ln -sf /usr/lib/systemd/system/avahi-daemon.service /etc/systemd/system/multi-user.target.wants/avahi-daemon.service



sudo rm /mnt/etc/resolv.conf
sudo mv /mnt/etc/resolv.conf.bak /mnt/etc/resolv.conf
sudo rm /mnt/usr/bin/qemu-arm-static

sudo umount /mnt/dev
sudo umount /mnt/proc
sudo umount /mnt/sys

sed -i 's/mmcblk0/mmcblk1/g' root/etc/fstab


EOT

sudo rm /mnt/etc/resolv.conf
sudo mv /mnt/etc/resolv.conf.bak /mnt/etc/resolv.conf
sudo rm /mnt/usr/bin/qemu-arm-static

sudo umount /mnt/dev
sudo umount /mnt/proc
sudo umount /mnt/sys

sudo umount /mnt/boot
sudo umount /mnt
sudo losetup --detach "/dev/loop0"
