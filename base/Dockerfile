# Start with nothing
FROM scratch

MAINTAINER jacobgadikian@gmail.com

# Add and decompress Arch Linux ARM rpi arm64 rootfs at /
ADD ArchLinuxARM-rpi-aarch64-latest.tar.gz /

# Pacman Keyring
RUN pacman-key --init \
		&& pacman-key --populate archlinuxarm

# Don't check disk space because we are in a container
RUN sed -i -e "s/^CheckSpace/#!!!CheckSpace/g" /etc/pacman.conf

RUN pacman -Syyu --noconfirm git sudo

# Add builduser
RUN useradd builduser -m && \
	passwd -d builduser && \
	printf 'builduser ALL=(ALL) ALL\n' | tee -a /etc/sudoers

USER builduser
RUN cd ~/ && \
		git clone https://aur.archlinux.org/yay.git yay && \
		cd yay && \
		makepkg -si --noconfirm --clean --rmdeps
USER root

# In the future, check that there is enough space
RUN sed -i -e "s/^#!!!CheckSpace/CheckSpace/g" /etc/pacman.conf
