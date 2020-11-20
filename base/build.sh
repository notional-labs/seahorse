#!/bin/bash

# Get the 64 bit rpi rootfs for Pi 3 and 4
wget -N --progress=bar:force:noscroll http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz

# Build the base image
docker buildx build --tag sos-base --platform linux/arm64 --load --progress plain .
