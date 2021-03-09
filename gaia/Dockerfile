FROM faddat/sos-lite

COPY motd /etc/motd

COPY gaia.service /etc/systemd/system/gaia.service


# Disk space thing
# Download starport, too
RUN sed -i -e "s/^CheckSpace/#!!!CheckSpace/g" /etc/pacman.conf && \
        # Dependencies & monitoring tools
        pacman -Syyu --noconfirm net-tools ufw vnstat iftop zerotier-one wget protobuf git && \
        # Install Gaia
        wget https://github.com/cosmos/gaia/releases/download/v4.0.5/gaiad-4.0.5-linux-arm64 && \
        mv gaiad-4.0.5-linux-arm64 /usr/bin && \
        chmod +x /usr/bin/gaiad && \
        systemctl enable gaia.service && \
        sed -i -e "s/^#!!!CheckSpace/CheckSpace/g" /etc/pacman.conf


# Add gaia user
RUN useradd gaia -m && \
	passwd -d gaia 