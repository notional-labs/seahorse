# SOS
[![gaia](https://github.com/faddat/sos/actions/workflows/gaia.yml/badge.svg)](https://github.com/faddat/sos/actions/workflows/gaia.yml) [![graviton](https://github.com/faddat/sos/actions/workflows/graviton.yml/badge.svg)](https://github.com/faddat/sos/actions/workflows/graviton.yml) [![iris](https://github.com/faddat/sos/actions/workflows/iris.yml/badge.svg)](https://github.com/faddat/sos/actions/workflows/iris.yml) [![akash](https://github.com/faddat/sos/actions/workflows/akash.yml/badge.svg)](https://github.com/faddat/sos/actions/workflows/akash.yml)

Arch-based Linux OS for P2P apps. 

Peer to peer applications tend to involve a complex stack and are therefore difficult to begin developing. SOS provides you with a complete development environment, As well as patterns and ideas to follow.

This image represents an opinionated approach to the construction of distributed and p2p applications.

### Variants

* Full
  * The full image is a development environment with P2P development tooling ready to go:
    * Starport
    * HNS or HNSD
    * IPFS
    * Gox
    * Docker
    * Go
    * Node.js
    * Zerotier
* Lite
  * Docker
  * Docker-compose

### Supported Devices & Platforms
SOS targets ARM64 and AMD64 processors. 

* Raspberry Pi 3
* Raspberry Pi 4
* Odroid C2

[Arch Linux](archlinux.org) was a very deliberate choice: In contrast to other distributions, arch packages are always up-to-date. Additionally, the arch user repository offers a wide variety of easy to install packages contributed by the community.


### Vital Information:

- designed to be consumed by your favorite CI system and used in the production of ready made system images.

  - defaults to GitHub Actions

- No binaries are used in the build process. All source code is copied to /spos so that users can easily rebuild the operating system. The Raspberry Pi 4 64 bit kernel is currently built elsewhere to save time, but we use a fully-open implementation. If you have spare time, you can build it from [source](https://aur.archlinux.org/packages/linux-raspberrypi4-aarch64/). It is blob-free.

- FAST
  - Full builds take ~30 minutes.
  - SPOS can produce a fully-cached image on a hetzner A61x in about 2 minutes.
  - Docker pull cann be used to load spos into your docker cache.

- one OS for every platform:
  - Cloud
    - AMI (AMD64 & ARM64)
  - Mobile (PinePhone, PineTab)
  - Router
    - Dawn
  - Laptop
    - Samsung
      - Chromebook Plus
    - Acer
      - Chromebook Flip
      - Chromebook R13
  - SBC
    - ~~Raspberry Pi 3 & 4~~
    - Odroid 
      - ~~C2~~
      - N2
    - Dragonboard 410C
    - Pine64
    - Rock64
