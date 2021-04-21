FROM faddat/sos-lite

# COPY motd /etc/motd

COPY akash.service /etc/systemd/system/akash.service

# Go Env Vars
ENV PATH=$PATH:/root/go/bin
ENV GOPATH=/root/go

# Akash Env
ENV AKASH_NET="https://raw.githubusercontent.com/ovrclk/net/master/mainnet"
ENV AKASH_VERSION="$(curl -s "$AKASH_NET/version.txt")
ENV AKASH_CHAIN_ID="$(curl -s "$AKASH_NET/chain-id.txt")


# Disk space thing
# Download starport, too
RUN sed -i -e "s/^CheckSpace/#!!!CheckSpace/g" /etc/pacman.conf && \
        # Dependencies & monitoring tools
        pacman -Syyu --noconfirm net-tools curl ufw vnstat unzip base-devel iftop zerotier-one wget protobuf git && \
        mkdir /root/go && \
        curl https://get.starport.network/starport! | bash && \
        echo "export PATH=$PATH:/root/go/bin" > /root/.bash_profile && \
        echo "export GOPATH=/root/go" >> /root/.bash_profile && \
        sed -i -e "s/^#!!!CheckSpace/CheckSpace/g" /etc/pacman.conf

# Add Akash user
RUN useradd akash -m && \
	passwd -d akash
USER akash

# Install Akash as Akash user
RUN echo 'export AKASH_NET="https://raw.githubusercontent.com/ovrclk/net/master/mainnet' > /home/akash/.bash_profile && \
        echo 'export AKASH_VERSION="$(curl -s "$AKASH_NET/version.txt")' /home/akash/.bash_profile && \
        echo 'export AKASH_CHAIN_ID="$(curl -s "$AKASH_NET/chain-id.txt")' /home/akash/.bash_profile && \
        echo 'PATH=$PATH:/home/akash/.bin' /home/akash/.bash_profile && \
        curl https://raw.githubusercontent.com/ovrclk/akash/master/godownloader.sh | sh -s -- "$AKASH_VERSION"

USER root

# Configure the first boot script
RUN echo "sleep 80" >> /usr/local/bin/firstboot.sh && \
        echo "runuser -l akash -c 'akash init --chain-id akashnet-2 akashpi-$RANDOM'" >> /usr/local/bin/firstboot.sh && \
        echo "curl -s "$AKASH_NET/genesis.json" > $HOME/.akash/config/genesis.json" && \
        echo "systemctl enable akash" >> /usr/local/bin/firstboot.sh && \
        echo "systemctl start akash" >> /usr/local/bin/firstboot.sh 
