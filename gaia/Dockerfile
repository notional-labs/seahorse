FROM faddat/sos-lite

COPY motd /etc/motd

COPY gaia.service /etc/systemd/system/gaia.service


# Disk space thing
# Download starport, too
RUN sed -i -e "s/^CheckSpace/#!!!CheckSpace/g" /etc/pacman.conf && \
        # Dependencies & monitoring tools
        pacman -Syyu --noconfirm wget sudo && \
        # Install Gaia
        wget https://github.com/cosmos/gaia/releases/download/v4.1.0/gaiad-v4.1.0-linux-arm64 && \
        mv gaiad-4.1.0-linux-arm64 /usr/bin/gaiad && \
        chmod +x /usr/bin/gaiad && \
        systemctl enable gaia.service && \
	echo 'INIT=gaiad init gaiapi$RANDOM' >> /usr/local/bin/firstboot.sh && \
	echo 'sudo -H -u gaia bash -c $INIT' >> /usr/local/bin/firstboot.sh && \
	echo 'sudo -H -u gaia bash -c wget https://github.com/cosmos/mainnet/raw/master/genesis.cosmoshub-4.json.gz && gzip -d genesis.cosmoshub-4.json.gz && mv genesis.cosmoshub-4.json ~/.gaia/config/genesis.json' >> /usr/local/bin/firstboot.sh && \
        sed -i -e "s/^#!!!CheckSpace/CheckSpace/g" /etc/pacman.conf


# Add gaia user
RUN useradd gaia -m && \
	passwd -d gaia 
