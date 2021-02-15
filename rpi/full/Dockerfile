# Start with nothing
FROM scratch

MAINTAINER jacobgadikian@gmail.com

# Add and decompress Arch Linux ARM rpi arm64 rootfs at /
ADD rpi/full/ArchLinuxARM-rpi-aarch64-latest.tar.gz /

# Pacman Keyring
# Don't check disk space because we are in a container
# FINISH GETTING PACMAN TO LIFE
# Get and install rpi 4 kernel
# Don't check disk space because we are in a container
RUN	sed -i -e "s/^CheckSpace/#!!!CheckSpace/g" /etc/pacman.conf && \
		pacman-key --init && \
		pacman-key --populate archlinuxarm && \
		pacman-db-upgrade && \
		pacman -R --noconfirm openssh linux-aarch64 uboot-raspberrypi && \
		pacman -Syy --noconfirm wget && \
		wget https://github.com/Biswa96/linux-raspberrypi4-aarch64/releases/download/5.4.79-2/linux-raspberrypi4-aarch64-5.4.79-2-aarch64.pkg.tar.xz && \
		wget https://github.com/Biswa96/linux-raspberrypi4-aarch64/releases/download/5.4.79-2/linux-raspberrypi4-aarch64-headers-5.4.79-2-aarch64.pkg.tar.xz && \
		pacman -U --noconfirm *.tar.xz && \
		rm *.tar.xz && \
		pacman --noconfirm -Syyu \
				archlinux-keyring \
				ca-certificates \
				ca-certificates-mozilla \
				ca-certificates-utils \
				bash-completion \
				parted \
				rng-tools \
				e2fsprogs \
				dropbear \
				sudo \
				unbound \
				sudo \ 
				fish \
				base-devel \
				neovim \
				colordiff \
				tree \
				unzip \
				unrar \
				htop \
				nmap \
				iftop \
				iotop \
				strace \
				lsof \
				git \
				jshon \
				nano \
				bc \
				wget \
				go-ipfs \
				jq \
				go 


# Add builduser
RUN useradd builduser -m && \
	passwd -d builduser && \
	printf 'builduser ALL=(ALL) ALL\n' | tee -a /etc/sudoers
USER builduser

# YAY
RUN cd ~/ && \
		git clone https://aur.archlinux.org/yay.git yay && \
		cd yay && \
		makepkg -si --noconfirm --clean --rmdeps && \
		cd .. && \ 
		rm -rf yay

# HNSD
RUN cd ~/ && \
		git clone https://github.com/faddat/hnsd-git && \
		cd hnsd-git && \
		makepkg -si --noconfirm --rmdeps --clean && \
		cd .. && \
		rm -rf hnsd-git

USER root

# Set System Locale
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
		 locale-gen && \
         userdel builduser && \
         sed -i -e "s/^#MAKEFLAGS=.*/MAKEFLAGS=-j5/g" /etc/makepkg.conf
ENV LC_ALL en_US.UTF-8


# Set root password to root and make sure the user changes it at next login
RUN echo "root:root" | chpasswd && \
		passwd -e root


# =================================================================
# CLEANUP: Make the OS new and shiny.
# =================================================================

# First Boot services
COPY ./contrib/firstboot.sh /usr/local/bin/firstboot.sh
COPY ./contrib/firstboot.service /etc/systemd/system/firstboot.service
COPY ./contrib/resizerootfs /usr/sbin/resizerootfs
COPY ./contrib/resizerootfs.service /etc/systemd/system
COPY ./contrib/ipfs.service /etc/systemd/system
# Copy DNS configuration so that stub resolver goes to hsd and falls back to GOOD(tm) public DNS
COPY ./contrib/dns /etc/systemd/resolved.conf
# HNSD Service: In testing hnsd has been unreliable
COPY ./contrib/hnsd.service /etc/systemd/system/hnsd.service
# Greet Users Warmly
COPY ./contrib/motd /etc/

# Enable services
# Use the Pi's Hardware rng.  You may wish to modify depending on your needs and desires: https://wiki.archlinux.org/index.php/Random_number_generation#Alternatives
RUN systemctl enable firstboot && \
		systemctl enable resizerootfs && \
		systemctl enable systemd-resolved && \
		chmod +x /usr/bin/hnsd && \
		chmod +x /usr/local/bin/firstboot.sh && \
		chmod +x /usr/sbin/resizerootfs && \
		systemctl enable hnsd && \
		# symlink systemd-resolved stub resolver to /etc/resolv/conf
		ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf && \
		systemctl enable dropbear && \
		echo 'RNGD_OPTS="-o /dev/random -r /dev/hwrng"' > /etc/conf.d/rngd && \
		systemctl disable haveged && \
		systemctl enable rngd && \
		pacman -R --noconfirm haveged && \
	        echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers.d/wheel 


# Add development environment dependencies
RUN echo "zerotier-cli join 35c192ce9bf02045" >> /usr/local/bin/firstboot.sh && \
        echo "ipfs init" /usr/local/bin/firstboot.sh

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
		`LC_ALL=C pacman -Qo /var/cache/* 2>&1 | grep 'error: No package owns' | awk '{print $5}'` && \
		sed -i -e "s/^#!!!CheckSpace/CheckSpace/g" /etc/pacman.conf
