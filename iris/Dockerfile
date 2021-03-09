FROM faddat/sos-lite

COPY motd /etc/motd

COPY 

# Go Env Vars
ENV PATH=$PATH:/root/go/bin
ENV GOPATH=/root/go


# Disk space thing
# Download starport, too
RUN sed -i -e "s/^CheckSpace/#!!!CheckSpace/g" /etc/pacman.conf && \
        # Dependencies & monitoring tools
        pacman -Syyu --noconfirm net-tools ufw vnstat iftop zerotier-one wget protobuf git && \
        mkdir /root/go && \
        echo 'export AKASH_NET="https://raw.githubusercontent.com/ovrclk/net/master/mainnet' > /root/.bash_profile && \
        echo 'export KASH_VERSION="$(curl -s "$AKASH_NET/version.txt")' /root/.bash_profile && \
        echo 'export AKASH_CHAIN_ID="$(curl -s "$AKASH_NET/chain-id.txt")' /root/.bash_profile && \
        echo 'PATH=$PATH:/root/.bin' /root/.bash_profile && \
        curl https://raw.githubusercontent.com/ovrclk/akash/master/godownloader.sh | sh -s -- "$AKASH_VERSION" && \
        git clone https://github.com/tendermint/starport && \
        cd starport && \
        make && \
        mv build/starport /usr/bin && \
        chmod +x /usr/bin/starport && \
        mkdir /root/go && \
        echo "export PATH=$PATH:/root/go/bin" > /root/.bash_profile && \
        echo "export GOPATH=/root/go" >> /root/.bash_profile && \
        sed -i -e "s/^#!!!CheckSpace/CheckSpace/g" /etc/pacman.conf


