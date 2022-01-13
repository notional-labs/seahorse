#!/bin/bash
# =======================================================================
# SOS image builder
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

# Get rootfs
# wget  https://download.manjaro.org/xfce/21.2.1/manjaro-xfce-21.2.1-minimal-220103-linux515.iso

# BUILD IMAGE
docker buildx build --tag sos-amd64 --file Dockerfile --platform linux/amd64 --progress plain --load ..

# TAG AND PUSH
docker tag sos-amd64  ghcr.io/notional-labs/sos
docker push ghcr.io/notional-labs/sos
