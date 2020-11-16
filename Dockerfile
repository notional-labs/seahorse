# =================================================================
# INIT: Consume args and the root filesystem
# =================================================================

# Start with nothing
FROM scratch

# Add and decompress Arch Linux ARM rpi arm64 rootfs at /
ADD ArchLinuxARM-rpi-aarch64-latest.tar.gz /

# =================================================================
# OS: This is where we set up the operating system.
# =================================================================

# Set System Locale
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
		&& locale-gen
ENV LC_ALL en_US.UTF-8


# Configure Kernel
RUN echo "HOOKS=(base udev block filesystems)" >> /etc/mkinitcpio.conf && \
		echo "MODULES=(bcm_phy_lib broadcom mdio_bcm_unimac genet)" >> /etc/mkinitcpio.conf


# Pacman Keyring
RUN pacman-key --init \
		&& pacman-key --populate archlinuxarm

# Don't check disk space because we are in a container
RUN sed -i -e "s/^CheckSpace/#!!!CheckSpace/g" /etc/pacman.conf

# Make Pacman Work
RUN pacman --noconfirm -Syy \
		&& pacman --noconfirm -S \
				glibc \
				pacman \
		&& pacman-db-upgrade \
		&& pacman --noconfirm -Syu \
		&& pacman --noconfirm -S \
				archlinux-keyring \
				ca-certificates \
				ca-certificates-mozilla \
				ca-certificates-utils

# Utilities
RUN pacman --noconfirm -Syyu \
				base \
				base-devel \
				vim \
				colordiff \
				tree \
				wget \
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
				rng-tools \
				nano \
				bc \
				e2fsprogs \
				parted \
				bash-completion


# dependencies is specific to our work
RUN pacman --noconfirm -Syyu \
				go \
				npm \
				go-ipfs \
				zerotier-one \
				yarn \
				jq \
				unbound


# disable dnssec
RUN echo "DNSSEC=no" >> /etc/systemd/resolved.conf && \
		systemctl enable systemd-resolved


# yay
RUN	useradd builduser -m && \
		passwd -d builduser && \
		printf 'builduser ALL=(ALL) ALL\n' | tee -a /etc/sudoers && \
		sudo -u builduser bash -c 'cd ~/ && git clone https://aur.archlinux.org/yay.git yay && cd yay && makepkg -s --noconfirm'


# Set up wifi, which has the side effect of allowing us to finish the build
# but would have taken systemd-networkd away from us.
# RUN pacman -Syyu --noconfirm wpa_supplicant wpa_actiond ifplugd crda dialog && \
#		systemctl enable netctl-auto@wlan0.service && \
#		systemctl enable netctl-ifplugd@eth0.service


# COPY wifi /etc/netctl/wlan0-SSID
# re-do for systemd-networkd later
# file wifi is better suited to netctl

# Use the Pi's Hardware rng.  You may wish to modify depending on your needs and desires: https://wiki.archlinux.org/index.php/Random_number_generation#Alternatives
RUN echo 'RNGD_OPTS="-o /dev/random -r /dev/hwrng"' > /etc/conf.d/rngd && \
		systemctl disable haveged && \
		systemctl enable rngd


# Maybe do things like this to make the shell pretty, later.
# RUN mkdir /tmp/linux-profile \
#		&& git clone https://github.com/mdevaev/linux-profile.git /tmp/linux-profile --depth=1 \
#		&& cp -a /tmp/linux-profile/{.bash_profile,.bashrc,.vimrc,.vimpagerrc,.vim} /etc/skel \
#		&& cp -a /tmp/linux-profile/{.bash_profile,.bashrc,.vimrc,.vimpagerrc,.vim} /root \
#		&& cp -a /tmp/linux-profile/{.bash_profile,.bashrc,.vimrc,.vimpagerrc,.vim} /home/alarm \
#		&& chown -R alarm:alarm /home/alarm/{.bash_profile,.bashrc,.vimrc,.vimpagerrc,.vim,.gitconfig} \
#		&& rm -rf /tmp/linux-profile


COPY motd /etc/

# Set root password to root
RUN echo "root:root" | chpasswd && \
		echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
		userdel -r -f alarm

# First Boot service
COPY firstboot.sh /usr/local/bin/firstboot.sh
COPY firstboot.service /etc/systemd/system/firstboot.service
RUN systemctl enable firstboot

# IPFS systemD service
COPY ipfs.service /etc/systemd/system/ipfs.service
RUN systemctl enable ipfs

# RUN pacman -S --needed --noconfirm sudo && \
#		useradd builduser -m && \
#		passwd -d builduser && \
#		printf 'builduser ALL=(ALL) ALL\n' | tee -a /etc/sudoers


# Get HSD and put bins on PATH
RUN git clone https://github.com/handshake-org/hsd && \
		cd hsd && \
		npm install --production --global
COPY hsd.service /etc/systemd/system/hsd.service
RUN systemctl enable ipfs

# symlink systemd-resolved stub resolver to /etc/resolv/conf
RUN ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Copy DNS configuration so that stub resolver goes to hsd
COPY dns /etc/systemd/resolved.conf.d/dns_servers.conf

# enable systemd-resolved
RUN systemctl enable systemd-resolved

# enable mdns
# RUN systemd-resolve --set-mdns=yes --interface=eth0

# enable zerotier-one
RUN systemctl enable zerotier-one

# give the wheel group sudo
RUN echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers.d/wheel



# mdns makes it easy to find your pi
# RUN pacman -S --noconfirm avahi nss-mdns && \
#		sed -i '/^hosts: /s/files dns/files mdns dns/' /etc/nsswitch.conf && \
#		systemctl enable avahi-daemon.service


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

# Let the Pi know where its disk is.
# Note: this varies between Pi3 and Pi4, both of which are supported by this script.
# mmcblk0 = pi3
# mmcblk1 = pi4


ENV LD_PRELOAD=
