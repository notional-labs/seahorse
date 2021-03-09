FROM faddat/sos-lite

# Go Env Vars
ENV PATH=$PATH:/root/go/bin
ENV GOPATH=/root/go


# Disk space thing
# Download starport, too
RUN sed -i -e "s/^CheckSpace/#!!!CheckSpace/g" /etc/pacman.conf && \
        # Dependencies & monitoring tools
        pacman -Syyu --noconfirm net-tools ufw vnstat iftop zerotier-one wget protobuf protobuf-go git go npm yarn base-devel && \
        mkdir /root/go && \
        git clone https://github.com/tendermint/starport && \
        cd starport && \
        make && \
        mv build/starport /usr/bin && \
        chmod +x /usr/bin/starport && \
        mkdir /root/go && \
        echo "export PATH=$PATH:/root/go/bin" > /root/.bash_profile && \
        echo "export GOPATH=/root/go" >> /root/.bash_profile && \
        sed -i -e "s/^#!!!CheckSpace/CheckSpace/g" /etc/pacman.conf


