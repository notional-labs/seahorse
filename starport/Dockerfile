FROM faddat/sos-lite

# Go Env Vars
ENV PATH=$PATH:/root/go/bin
ENV GOPATH=/root/go


# Disk space thing
# Download starport, too
RUN sed -i -e "s/^CheckSpace/#!!!CheckSpace/g" /etc/pacman.conf && \
        # Dependencies & monitoring tools
        pacman -Syyu --noconfirm net-tools vnstat wget protobuf git go npm yarn base-devel && \
        mkdir /root/go && \
        curl https://get.starport.network/starport! | bash && \
        echo "export PATH=$PATH:/root/go/bin" > /root/.bash_profile && \
        echo "export GOPATH=/root/go" >> /root/.bash_profile && \
        sed -i -e "s/^#!!!CheckSpace/CheckSpace/g" /etc/pacman.conf


