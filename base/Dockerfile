# Start with nothing
FROM scratch

MAINTAINER jacobgadikian@gmail.com

# Add and decompress Arch Linux ARM rpi arm64 rootfs at /
ADD ArchLinuxARM-rpi-aarch64-latest.tar.gz /

# Pacman Keyring
# Don't check disk space because we are in a container
RUN sed -i -e "s/^CheckSpace/#!!!CheckSpace/g" /etc/pacman.conf && \
		pacman-key --init && \
		pacman-key --populate archlinuxarm && \
		pacman -Syyu --noconfirm git sudo base-devel

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
# In the future, check that there is enough space
RUN echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers.d/wheel && \
		sed -i -e "s/^#!!!CheckSpace/CheckSpace/g" /etc/pacman.conf
