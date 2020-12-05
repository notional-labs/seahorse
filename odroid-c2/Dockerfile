# Start with nothing
FROM scratch

MAINTAINER jacobgadikian@gmail.com

# Add and decompress Arch Linux ARM rpi arm64 rootfs at /
ADD ArchLinuxARM-odroid-c2-latest.tar.gz /

# Pacman Keyring
# Don't check disk space because we are in a container
RUN sed -i -e "s/^CheckSpace/#!!!CheckSpace/g" /etc/pacman.conf && \
		pacman-key --init && \
		pacman-key --populate archlinuxarm && \
		pacman-db-upgrade && \
		pacman -Syyu --noconfirm git sudo base-devel archlinux-keyring \
		ca-certificates \
		ca-certificates-mozilla \
		ca-certificates-utils \
		bash-completion \
		parted \
		rng-tools \
		e2fsprogs \
		dropbear \
		sudo \
		git \
		unbound

# Add builduser
RUN useradd builduser -m && \
	passwd -d builduser && \
	printf 'builduser ALL=(ALL) ALL\n' | tee -a /etc/sudoers

USER builduser

# YAY
RUN cd ~/ && \
		git clone https://aur.archlinux.org/yay.git yay && \
		cd yay && \
		makepkg -si --noconfirm --clean --rmdeps
USER root

# give the wheel group sudo
RUN echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers.d/wheel

# In the future, check that there is enough space
RUN sed -i -e "s/^#!!!CheckSpace/CheckSpace/g" /etc/pacman.conf
