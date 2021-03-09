FROM faddat/sos-lite

COPY motd /etc/motd


# Disk space thing
# Download starport, too
RUN sed -i -e "s/^CheckSpace/#!!!CheckSpace/g" /etc/pacman.conf && \
        pacman -Syyu --noconfirm net-tools ufw vnstat iftop zerotier-one wget protobuf git go npm yarn && \
        mkdir starport && \
        cd starport && \
        wget -O starport_0.14.0_linux_arm64.tar.gz https://github.com/tendermint/starport/releases/download/v0.14.0/starport_0.14.0_linux_arm64.tar.gz && \
        tar xvf starport_0.14.0_linux_arm64.tar.gz && \
        mv starport /usr/bin && \
        chmod +x /usr/bin/starport && \
        sed -i -e "s/^#!!!CheckSpace/CheckSpace/g" /etc/pacman.conf