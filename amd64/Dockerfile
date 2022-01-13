# Start with nothing
# We're building a Manjaro linux image for Raspberry Pi 4.
FROM scratch

LABEL maintainer="jacobgadikian@gmail.com"


# Add and decompress ~Arch~ Manjaro Linux ARM rpi arm64 rootfs at /
# This used to be an arch build, but Manjaro really has a better selection of kernels, so we will contribute there.
ADD amd64/manjaro-xfce-21.2.1-minimal-220103-linux510.iso /




# INSTALL OS PACKAGES FOR NOW
# RUN pacman-mirrors --api --set-branch unstable
RUN pacman-key --init
RUN pacman-key --populate archlinux
RUN pacman -Syy --noconfirm sed
# Don't check to make sure there's free disk space when using pacman
RUN sed -i -e "s/^CheckSpace/#!!!CheckSpace/g" /etc/pacman.conf
RUN pacman-mirrors --fasttrack 5


# RUN pacman-key --refresh-keys





# Install packages
RUN pacman -Syyu --noconfirm sed wget base linux linux-firmware ca-certificates ca-certificates-mozilla ca-certificates-utils parted rng-tools e2fsprogs dropbear unbound fakeroot



# Make the Odroid c2 happy: device specific stuff
# RUN pacman -Syyu --noconfirm linux-vim uboot-odroid-c2-mainline plymouth plymouth-theme-manjaro xf86-video-fbturbo-git btrfs-progs fbset amlogic oc2-post-install


# Set System Locale, set build config, get rid of the builduser
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
		 locale-gen && \
		 sed -i -e "s/^#MAKEFLAGS=.*/MAKEFLAGS=-j5/g" /etc/makepkg.conf



# Set root password to root
RUN echo "root:root" | chpasswd



# =================================================================
# CLEANUP: Make the OS new and shiny.
# =================================================================

# First Boot services
COPY ./contrib/firstboot.sh /usr/local/bin/firstboot.sh
COPY ./contrib/firstboot.service /etc/systemd/system/firstboot.service
COPY ./contrib/resizerootfs /usr/sbin/resizerootfs
COPY ./contrib/resizerootfs.service /etc/systemd/system


# Greet Users Warmly
# TODO: Update to Notional Brand
COPY ./contrib/motd /etc/

# Enable services
# Use the Pi's Hardware rng.  You may wish to modify depending on your needs and desires: https://wiki.archlinux.org/index.php/Random_number_generation#Alternatives
RUN systemctl enable firstboot && \
		systemctl enable resizerootfs && \
		chmod +x /usr/local/bin/firstboot.sh && \
		chmod +x /usr/sbin/resizerootfs && \
# SYMLINK RESOLVED STUB RESOLVER /etc/resolv/conf
#		ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf && \
		systemctl enable dropbear && \
		echo 'RNGD_OPTS="-o /dev/random -r /dev/hwrng"' > /etc/conf.d/rngd && \
#		systemctl disable haveged && \
		systemctl enable rngd
#		pacman -R --noconfirm haveged && \
#		echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers.d/wheel

RUN sed -i -e "s/^#!!!CheckSpace/CheckSpace/g" /etc/pacman.conf

# Remove cruft and let pacman check for free disk space
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
