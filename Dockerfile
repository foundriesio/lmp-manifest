# Build container tools
FROM ubuntu:20.04 AS container-tools
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y wget git make \
	libgpgme-dev libassuan-dev libbtrfs-dev libdevmapper-dev pkg-config

RUN wget -P /tmp https://go.dev/dl/go1.18.linux-amd64.tar.gz && \
	tar -C /usr/local -xzf /tmp/go1.18.linux-amd64.tar.gz
ENV PATH /usr/local/go/bin:$PATH

# Build skopeo
RUN git clone https://github.com/containers/skopeo.git /skopeo && \
	cd /skopeo && git checkout -q v1.8.0 && \
	GO_DYN_FLAGS= CGO_ENABLED=0 BUILDTAGS=containers_image_openpgp DISABLE_DOCS=1 make

# Build ostreeuploader, aka fiopush/fiocheck
FROM ubuntu:20.04 AS fiotools
RUN apt-get update
RUN apt-get install -y wget git gcc make -y
RUN wget -P /tmp https://go.dev/dl/go1.18.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf /tmp/go1.18.linux-amd64.tar.gz
ENV PATH /usr/local/go/bin:$PATH

RUN git clone https://github.com/foundriesio/ostreeuploader.git /ostreeuploader && \
    cd /ostreeuploader && git checkout -q 2022.12 && \
    cd /ostreeuploader && make


FROM ubuntu:20.04

# bitbake requires a utf8 filesystem encoding
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ARG DEBIAN_FRONTEND=noninteractive
ARG DEV_USER_NAME=Builder
ARG DEV_USER=builder
ARG DEV_USER_PASSWD=builder

# FIO PPA for additional dependencies and newer packages
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	   software-properties-common \
	&& add-apt-repository ppa:fio-maintainers/ppa \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		android-sdk-libsparse-utils android-sdk-ext4-utils ca-certificates \
		chrpath cpio diffstat file gawk g++ iproute2 iputils-ping less libmagickwand-dev \
		libmath-prime-util-perl libsdl1.2-dev libssl-dev locales \
		openjdk-11-jre openssh-client perl-modules python3 python3-requests \
		make patch repo sudo texinfo vim-tiny wget whiptail libelf-dev git-lfs screen \
		socket corkscrew curl xz-utils tcl libtinfo5 device-tree-compiler python3-pip python3-dev \
		tmux libncurses-dev vim zstd lz4 liblz4-tool libc6-dev-i386 \
		awscli docker-compose \
	&& ln -s /usr/bin/python3 /usr/bin/python \
	&& pip3 --no-cache-dir install expandvars jsonFormatter \
	&& apt-get autoremove -y \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* \
	&& locale-gen en_US.UTF-8

# Create the user which will run the SDK binaries.
RUN useradd -c $DEV_USER_NAME \
		-d /home/$DEV_USER \
		-G sudo,dialout,floppy,plugdev,users \
		-m \
		-s /bin/bash \
		$DEV_USER

# Add default password for the SDK user (useful with sudo)
RUN echo $DEV_USER:$DEV_USER_PASSWD | chpasswd

# Initialize development environment for $DEV_USER.
RUN sudo -u $DEV_USER -H git config --global credential.helper 'cache --timeout=3600'

# Install ostreeuploader, aka fiopush/fiocheck
COPY --from=fiotools /ostreeuploader/bin/fiopush /usr/bin/
COPY --from=fiotools /ostreeuploader/bin/fiocheck /usr/bin/
ENV FIO_PUSH_CMD /usr/bin/fiopush
ENV FIO_CHECK_CMD /usr/bin/fiocheck

# Install skopeo
COPY --from=container-tools /skopeo/bin/skopeo /usr/bin

# Install docker CLI, v20.10.14, required by the oe-builtin App preload
RUN mkdir -p /etc/apt/keyrings \
	&& curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
	&& apt-get update && apt-get install -y docker-ce-cli=5:20.10.14~3-0~ubuntu-focal \
	&& apt-get clean && rm -rf /var/lib/apt/lists/*

# Install docker compose CLI plugin, v2.6.0, required by the oe-builtin App preload, `docker compose config`
RUN mkdir -p /usr/lib/docker/cli-plugins \
	&& wget https://github.com/docker/compose/releases/download/v2.6.0/docker-compose-linux-x86_64 -O /usr/lib/docker/cli-plugins/docker-compose \
	&& chmod +x /usr/lib/docker/cli-plugins/docker-compose
