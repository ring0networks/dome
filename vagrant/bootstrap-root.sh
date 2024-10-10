#!/bin/bash -ex

# from: https://github.com/p4lang/tutorials/tree/master/vm-ubuntu-24.04

sudo useradd -m -s /bin/bash dome
sudo chown -R dome:dome /home/dome
echo "dome:dome" | sudo chpasswd
echo "dome ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99_dome
chmod 440 /etc/sudoers.d/99_dome
usermod -aG tcpdump,dome,vagrant,sudo dome

export DEBIAN_FRONTEND=noninteractive
apt update -y
apt install -y --fix-missing \
  autoconf \
  automake \
  bison \
  build-essential \
  ca-certificates \
  clang \
  cmake \
  cpp \
  curl \
  emacs \
  zile \
  flex \
  g++ \
  git \
  dwarves \
  clang \
  iproute2 \
  libelf-dev \
  libffi-dev \
  libfl-dev \
  libgc-dev \
  libgflags-dev \
  libgmp-dev \
  libpcap-dev \
  libpython3-dev \
  libreadline-dev \
  libssl-dev \
  libtool \
  libtool-bin \
  linux-generic-hwe-22.04-edge \
  linux-headers-generic-hwe-22.04-edge \
  linux-tools-generic-hwe-22.04-edge \
  linux-tools-common \
  llvm \
  lua5.4 \
  make \
  m4 \
  iptables \
  net-tools \
  pkg-config \
  siege \
  wrk \
  tcpdump \
  unzip \
  valgrind \
  vim \
  neovim \
  npm \
  wget \
  xcscope-el \
  xterm

apt install -y --reinstall gcc-12
apt upgrade -y

apt autoremove -y
apt autoclean -y

