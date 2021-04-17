FROM faddat/sos-lite

# COPY motd /etc/motd

COPY iris.service /etc/systemd/system/iris.service 

# Go Env Vars
ENV PATH=$PATH:/root/go/bin
ENV GOPATH=/root/go


# Disk space thing
# Download starport, too
RUN sed -i -e "s/^CheckSpace/#!!!CheckSpace/g" /etc/pacman.conf && \
        # Dependencies & monitoring tools
        pacman -Syyu --noconfirm vnstat base-devel iftop mom go git && \
        mkdir /root/go && \
        git clone https://github.com/irisnet/irishub && \
        cd irishub && \
        git checkout v1.0.1 && \
        make && \
        echo "export PATH=$PATH:/root/go/bin" > /root/.bash_profile && \
        echo "export GOPATH=/root/go" >> /root/.bash_profile && \
        sed -i -e "s/^#!!!CheckSpace/CheckSpace/g" /etc/pacman.conf
