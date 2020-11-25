FROM faddat/sos

RUN pacman -Syyu --noconfirm neovim \
		 colordiff \
		tree \
		unzip \
		unrar \
		htop \
		nmap \
		iftop \
		iotop \
		strace \
		lsof \
		git \
		jshon \
		nano \
		bc \
		wget \
		go-ipfs \
		jq \
		go \
		fish


# Add development environment dependencies
RUN echo "zerotier-cli join 35c192ce9bf02045" >> /usr/local/bin/firstboot.sh && \
echo "ipfs init" /usr/local/bin/firstboot.sh
