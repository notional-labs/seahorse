# Start with nothing
FROM scratch

LABEL maintainer="jacobgadikian@gmail.com"
ENV LC_ALL en_US.UTF-8


# Add and decompress ~Arch~ Manjaro Linux ARM rpi arm64 rootfs at /
# This used to be an arch build, but Manjaro really has a better selection of kernels, so we will contribute there. 
ADD rpi/Manjaro-ARM-aarch64-latest.tar.gz /

# INSTALL OS PACKAGES FOR NOS
RUN pacman-key --init && \
		pacman -Syy && \
		pacman-key --populate archlinuxarm manjaro && \
		pacman-key --refresh-keys && \
		pacman-db-upgrade && \
		pacman -Syyu --noconfirm sed wget archlinux-keyring linux-rpi4-mainline ca-certificates ca-certificates-mozilla ca-certificates-utils bash-completion fish fisher parted sudo rng-tools e2fsprogs dropbear unbound fakeroot



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
COPY ./contrib/dns /etc/systemd/resolved.conf
# Greet Users Warmly
COPY ./contrib/motd /etc/

# Enable services
# Use the Pi's Hardware rng.  You may wish to modify depending on your needs and desires: https://wiki.archlinux.org/index.php/Random_number_generation#Alternatives
RUN systemctl enable firstboot && \
		systemctl enable resizerootfs && \
		systemctl enable systemd-resolved && \
		chmod +x /usr/local/bin/firstboot.sh && \
		chmod +x /usr/sbin/resizerootfs && \
# SYMLINK RESOLVED STUB RESOLVER /etc/resolv/conf
		ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf && \
		systemctl enable dropbear && \
		echo 'RNGD_OPTS="-o /dev/random -r /dev/hwrng"' > /etc/conf.d/rngd && \
		systemctl disable haveged && \
		systemctl enable rngd && \
		pacman -R --noconfirm haveged && \
		echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers.d/wheel 

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
