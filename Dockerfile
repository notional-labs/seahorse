# =================================================================
# INIT: Import the root filesystem.
# Later, we can use ARG + ENV to build for any arm64 device:
# https://archlinuxarm.org/platforms/armv8
# =================================================================

# Start with SOS base image
FROM docker.io/faddat/sos-base

MAINTAINER jacobgadikian@gmail.com

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
RUN pacman-db-upgrade
RUN pacman --noconfirm -Syyu \
				archlinux-keyring \
				ca-certificates \
				ca-certificates-mozilla \
				ca-certificates-utils \
				base \
				bash-completion \
				parted \
				rng-tools \
				e2fsprogs \
				dropbear \
				sudo \
				git \
				base-devel \
				unbound


# build with the whole pi by default
RUN sed -i -e "s/^#MAKEFLAGS=.*/MAKEFLAGS=-j5/g" /etc/makepkg.conf

# Enable dropbear
RUN systemctl enable dropbear


# INSTALL HNSD
USER builduser
RUN cd ~/ && \
		git clone https://github.com/faddat/hnsd-git && \
		cd hnsd-git && \
		makepkg -si --noconfirm --rmdeps --clean
USER root


# Use the Pi's Hardware rng.  You may wish to modify depending on your needs and desires: https://wiki.archlinux.org/index.php/Random_number_generation#Alternatives
RUN echo 'RNGD_OPTS="-o /dev/random -r /dev/hwrng"' > /etc/conf.d/rngd && \
		systemctl disable haveged && \
		systemctl enable rngd

# Set root password to root
RUN echo "root:root" | chpasswd

# enable systemd-resolved
RUN systemctl enable systemd-resolved

# =================================================================
# CLEANUP: Make the OS new and shiny.
# =================================================================

# Remove build tools
# RUN pacman -R --noconfirm base-devel
# Leave base-devel for now so we can ship a build.  Later figure out how to cleanly remove it.

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

# First Boot services
COPY ./contrib/firstboot.sh /usr/local/bin/firstboot.sh
COPY ./contrib/firstboot.service /etc/systemd/system/firstboot.service
COPY ./contrib/resizerootfs /usr/sbin/resizerootfs
COPY ./contrib/resizerootfs.service /etc/systemd/system
# Copy DNS configuration so that stub resolver goes to hsd and falls back to GOOD(tm) public DNS
COPY contrib/dns /etc/systemd/resolved.conf
# HNSD Service: In testing hnsd has been unreliable
COPY contrib/hnsd.service /etc/systemd/system/hnsd.service
# Greet Users Warmly
COPY contrib/motd /etc/

# Start services
RUN systemctl enable firstboot && \
	systemctl enable resizerootfs && \
	chmod +x /usr/local/bin/firstboot.sh && \
	chmod +x /usr/sbin/resizerootfs && \
	systemctl enable systemd-resolved && \
	systemctl enable hnsd && \
	chmod +x /usr/bin/hnsd && \
	# symlink systemd-resolved stub resolver to /etc/resolv/conf
	ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf








