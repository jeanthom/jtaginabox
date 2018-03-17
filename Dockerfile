FROM debian:jessie-slim

RUN \
  apt-get update && \
  apt-get -o APT::Install-Suggests=0 -o APT::Install-Recommends=0 -y install \
	valac \
	libgtk-3-dev \
	libusb-1.0-0-dev \
	libvte-2.91-dev \
	build-essential \
	libglib2.0-dev \
	libxml2-utils \
	automake \
	autotools-dev \
	autopoint \
	libtool \
	python-dev \
	tree \
	gcc-arm-none-eabi \
	libnewlib-arm-none-eabi \
	wget \
	squashfs-tools && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /jtaginabox
COPY . .
RUN make appimage
