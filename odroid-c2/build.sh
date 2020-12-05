#!/bin/bash

# Fail on error
set -exo pipefail

# Print each command
set -o xtrace

# Get the 64 bit rpi rootfs for Pi 3 and 4
wget -N --progress=bar:force:noscroll wget http://os.archlinuxarm.org/os/ArchLinuxARM-odroid-c2-latest.tar.gz

# Build the base image
docker buildx build --tag faddat/sos-base:c2 --platform linux/arm64 --load --cache-from faddat/sos-base:c2cache --cache-to faddat/sos-base:c2cache --progress plain .

# TAG AND PUSH
docker push faddat/sos-base:c2

# EXTRACT IMAGE
# Make a temporary directory
rm -rf .tmp | true
mkdir .tmp

# remove anything in the way of extraction
docker run --rm --tty --volume $(pwd)/./.tmp:/root/./.tmp --workdir /root/./.tmp/.. faddat/toolbox rm -rf ./.tmp/result-rootfs

# save the image to result-rootfs.tar
docker save --output ./.tmp/result-rootfs.tar faddat/sos-base:c2

# Extract the image using docker-extract
docker run --rm --tty --volume $(pwd)/./.tmp:/root/./.tmp --workdir /root/./.tmp/.. faddat/toolbox /tools/docker-extract --root ./.tmp/result-rootfs  ./.tmp/result-rootfs.tar

# Set hostname while the image is just in the filesystem.
sudo bash -c "echo sos > ./.tmp/result-rootfs/etc/hostname"


# ===================================================================================
# IMAGE: Make a .img file and compress it.
# Uses Techniques from Disconnected Systems:
# https://disconnected.systems/blog/raspberry-pi-archlinuxarm-setup/
# ===================================================================================


# Unmount anything on the loop device
sudo umount /dev/loop0p2 || true
sudo umount /dev/loop0p1 || true


# Detach from the loop device
sudo losetup -d /dev/loop0 || true

# Unmount anything on the loop device
sudo umount /dev/loop0p2 || true
sudo umount /dev/loop0p1 || true


# Create a folder for images
rm -rf images || true
mkdir -p images

# Make the image file
fallocate -l 3G "images/sos-base.img"

# loop-mount the image file so it becomes a disk
export LOOP=$(sudo losetup --find --show images/sos-full.img)

# partition the loop-mounted disk
sudo parted --script $LOOP mklabel msdos
sudo parted --script $LOOP mkpart primary ext4 0% 100%

# format the newly partitioned loop-mounted disk
sudo mkfs.vfat -F32 $(echo $LOOP)p1
sudo mkfs.ext4 -F $(echo $LOOP)p2

# Use the toolbox to copy the rootfs into the filesystem we formatted above.
# * mount the disk's /boot and / partitions
# * use rsync to copy files into the filesystem
# make a folder so we can mount the boot partition
# soon will not use toolbox

sudo mkdir -p mnt/boot mnt/rootfs
sudo mount $(echo $LOOP)p1 mnt/boot
sudo mount $(echo $LOOP)p2 mnt/rootfs
sudo rsync -a ./.tmp/result-rootfs/boot/* mnt/boot
sudo rsync -a ./.tmp/result-rootfs/* mnt/rootfs --exclude boot
sudo mkdir mnt/rootfs/boot
sudo umount mnt/boot mnt/rootfs

# Tell pi where its memory card is:  This is needed only with the mainline linux kernel provied by linux-aarch64
# sed -i 's/mmcblk0/mmcblk1/g' ./.tmp/result-rootfs/etc/fstab

# Drop the loop mount
sudo losetup -d $LOOP

# Delete .tmp and mnt
sudo rm -rf ./.tmp
sudo rm -rf mnt


