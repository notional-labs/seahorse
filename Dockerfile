# =================================================================
# INIT: Import the root filesystem.
# Later, we can use ARG + ENV to build for any arm64 device:
# https://archlinuxarm.org/platforms/armv8
# =================================================================

# Start with nothing
FROM scratch

MAINTAINER jacobgadikian@gmail.com

# Add and decompress Arch Linux ARM rpi arm64 rootfs at /
ADD ArchLinuxARM-rpi-aarch64-latest.tar.gz /

# =================================================================
# OS: This is where we set up the operating system.
# =================================================================

# Set System Locale
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
		&& locale-gen
ENV LC_ALL en_US.UTF-8

# Pacman Keyring
RUN pacman-key --init \
		&& pacman-key --populate archlinuxarm

# Don't check disk space because we are in a container
RUN sed -i -e "s/^CheckSpace/#!!!CheckSpace/g" /etc/pacman.conf

# Make Pacman Work
RUN pacman -R --noconfirm openssh linux-aarch64 uboot-raspberrypi

# GET AND INSTALL KERNEL
RUN curl -LJO https://github.com/Biswa96/linux-raspberrypi4-aarch64/releases/download/5.4.72-1/linux-raspberrypi4-aarch64-5.4.72-1-aarch64.pkg.tar.xz && \
		curl -LJO https://github.com/Biswa96/linux-raspberrypi4-aarch64/releases/download/5.4.72-1/linux-raspberrypi4-aarch64-headers-5.4.72-1-aarch64.pkg.tar.xz && \
		pacman -U --noconfirm *.tar.xz && \
		rm *.tar.xz


# FINISH GETTING PACMAN TO LIFE
RUN pacman --noconfirm -Syyu glibc pacman
RUN pacman-db-upgrade
RUN pacman --noconfirm -Syyu \
				archlinux-keyring \
				ca-certificates \
				ca-certificates-mozilla \
				ca-certificates-utils

# Utilities
RUN pacman --noconfirm -Syyu \
				base \
				bash-completion \
				parted \
				rng-tools \
				e2fsprogs \
				dropbear \
				sudo \
				git \
				base-devel


# dependencies is specific to our work
RUN pacman --noconfirm -Syyu \
				npm \
				zerotier-one \
				unbound

# Enable dropbear
RUN systemctl enable dropbear

# give the wheel group sudo
RUN echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers.d/wheel

# disable dnssec
RUN echo "DNSSEC=no" >> /etc/systemd/resolved.conf && \
		systemctl enable systemd-resolved

# Add builduser
RUN useradd builduser -m && \
	passwd -d builduser && \
	printf 'builduser ALL=(ALL) ALL\n' | tee -a /etc/sudoers


# INSTALL YAY: WE BECOME THE BUILDUSER HERE
USER builduser
RUN cd ~/ && \
		git clone https://aur.archlinux.org/yay.git yay && \
		cd yay && \
		makepkg -si --noconfirm --clean --rmdeps

# INSTALL HNSD
RUN cd ~/ && \
		git clone https://github.com/faddat/hnsd-git && \
		cd hnsd-git && \
		makepkg -si --noconfirm --rmdeps --clean
USER root
COPY cotrib/hnsd.service /etc/systemd/system/hnsd.service
RUN systemctl enable hnsd


# Use the Pi's Hardware rng.  You may wish to modify depending on your needs and desires: https://wiki.archlinux.org/index.php/Random_number_generation#Alternatives
RUN echo 'RNGD_OPTS="-o /dev/random -r /dev/hwrng"' > /etc/conf.d/rngd && \
		systemctl disable haveged && \
		systemctl enable rngd

# Greet Users Warmly
COPY contrib/motd /etc/

# Set root password to root
RUN echo "root:root" | chpasswd

# First Boot service
COPY contrib/firstboot.sh /usr/local/bin/firstboot.sh
COPY contrib/firstboot.service /etc/systemd/system/firstboot.service
RUN systemctl enable firstboot

# IPFS systemD service
COPY contrib/ipfs.service /etc/systemd/system/ipfs.service
RUN systemctl enable ipfs

# symlink systemd-resolved stub resolver to /etc/resolv/conf
RUN ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Copy DNS configuration so that stub resolver goes to hsd
COPY contrib/dns /etc/systemd/resolved.conf.d/dns_servers.conf

# enable systemd-resolved
RUN systemctl enable systemd-resolved

# enable zerotier-one
RUN systemctl enable zerotier-one

# =================================================================
# CLEANUP: Make the OS new and shiny.
# =================================================================

# Remove cruft
RUN rm -rf \
		/etc/*- \
		/var/lib/systemd/* \
		/var/lib/private/* \
		/var/log/* \
		/var/tmp/* \
		/tmp/* \
		/root/.bash_history \
		/root/.cache \
		/home/*/.bash_history \
		/home/*/.cache \
		`LC_ALL=C pacman -Qo /var/cache/* 2>&1 | grep 'error: No package owns' | awk '{print $5}'`

# In the future, check that there is enough space
RUN sed -i -e "s/^#!!!CheckSpace/CheckSpace/g" /etc/pacman.conf

