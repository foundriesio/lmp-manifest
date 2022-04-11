# Build ostreeuploader, aka fiopush/fiocheck
FROM ubuntu:20.04
RUN apt-get update
RUN apt-get install -y wget git gcc make -y
RUN wget -P /tmp https://go.dev/dl/go1.18.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf /tmp/go1.18.linux-amd64.tar.gz
ENV PATH /usr/local/go/bin:$PATH

RUN git clone https://github.com/foundriesio/ostreeuploader.git /ostreeuploader && \
    cd /ostreeuploader && git checkout 0372bd4386a28ed02a1cd9f643c9e58700db4367 && \
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
		tmux libncurses-dev vim zstd lz4 liblz4-tool \
	&& ln -s /usr/bin/python3 /usr/bin/python \
	&& pip3 --no-cache-dir install jsonFormatter \
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
COPY --from=0 /ostreeuploader/bin/fiopush /usr/bin/
COPY --from=0 /ostreeuploader/bin/fiocheck /usr/bin/
ENV FIO_PUSH_CMD /usr/bin/fiopush
ENV FIO_CHECK_CMD /usr/bin/fiocheck
