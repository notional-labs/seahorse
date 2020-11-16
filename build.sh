#!/bin/bash
# =======================================================================
# StarportOS image builder
# =======================================================================


# This process uses tools and a design pattern first developed by the pikvm team for their pi-builder and os tools.
# the biggest differences between this process and theirs are:
# * we use docker buildx so we don't need to deal with qemu directly.
# * we are not offering as many choices to users and are designing around automation.
# Later we can make this work for more devices and platforms with nearly the same technique.
# Reasonable build targets include: https://archlinuxarm.org/platforms/armv8
# For example, the Odroid-N2 is the same software-wise as our Router!

# Fail on error
set -exo pipefail

# Print each command
set -o xtrace

# Get the 64 bit rpi rootfs for Pi 3 and 4
wget -N --progress=bar:force:noscroll http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz

# PiShrink, also auto-expands on first boot.  Magic.
# wget https://raw.githubusercontent.com/Drewsif/PiShrink/master/pishrink.sh
# chmod +x pishrink.sh
# sudo mv pishrink.sh /usr/local/bin

# Reintroduce later
# export ROOT_PASSWD=root


# BUILD IMAGE
# --build-arg ROOT_PASSWD
docker buildx build --tag starport --platform linux/arm64 --load --progress plain .


# PREPARE TOOLBOX
docker buildx build --rm --tag toolbox --file toolbox/Dockerfile.root --load --progress plain toolbox


# EXTRACT IMAGE
# Make a temporary directory
rm -rf .tmp | true
mkdir .tmp

# remove anything in the way of extraction
docker run --rm --tty --volume $(pwd)/./.tmp:/root/./.tmp --workdir /root/./.tmp/.. toolbox rm -rf ./.tmp/result-rootfs

# save the image to result-rootfs.tar
docker save --output ./.tmp/result-rootfs.tar starport

# Extract the image using docker-extract
docker run --rm --tty --volume $(pwd)/./.tmp:/root/./.tmp --workdir /root/./.tmp/.. toolbox /tools/docker-extract --root ./.tmp/result-rootfs  ./.tmp/result-rootfs.tar

# Set hostname
bash -c "echo starport > ./.tmp/result-rootfs/etc/hostname"


# ===================================================================================
# IMAGE: Make a .img file and compress it.
# Uses Techniques from Disconnected Systems:
# https://disconnected.systems/blog/raspberry-pi-archlinuxarm-setup/
# ===================================================================================

# Create a folder for images

rm -rf images | true
mkdir -p images

# Make the image file
fallocate -l 8G "images/starport.img"

losetup -d /dev/loop0 || true

# loop-mount the image file so it becomes a disk
losetup --find --show images/starport.img

# partition the loop-mounted disk
parted --script /dev/loop0 mklabel msdos
parted --script /dev/loop0 mkpart primary fat32 0% 200M
parted --script /dev/loop0 mkpart primary ext4 200M 100%

# format the newly partitioned loop-mounted disk
mkfs.vfat -F32 /dev/loop0p1
mkfs.ext4 -F /dev/loop0p2


# Use the toolbox to copy the rootfs into the filesystem
# * mount the disk's /boot and / partitions
# * use rsync to copy files into the filesystem
# make a folder so we can mount the boot partition

docker run --rm --tty --privileged --volume $(pwd)/./.tmp:/root/./.tmp --workdir /root/./.tmp/.. toolbox bash -c " \
		mkdir -p mnt/boot mnt/rootfs && \
		mount /dev/loop0p1 mnt/boot && \
		mount /dev/loop0p2 mnt/rootfs && \
		rsync -a --info=progress2 ./.tmp/result-rootfs/boot/* mnt/boot && \
		rsync -a --info=progress2 ./.tmp/result-rootfs/* mnt/rootfs --exclude boot && \
		mkdir mnt/rootfs/boot && \
		umount mnt/boot mnt/rootfs
	"

# Tell pi where its memory card is
sed -i 's/mmcblk0/mmcblk1/g' ./.tmp/result-rootfs/etc/fstab

# Drop the loop mount
losetup -d /dev/loop0

# Compress the image
pishrink.sh -Z -a -p images/starport.img
