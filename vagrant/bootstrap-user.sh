#!/bin/bash -ex

# from: https://medium.com/@lourival.neto/is-ebpf-driving-you-crazy-let-it-run-lunatik-instead-4aca7d63e6fd

export KERNEL_VERSION=$(uname -r)

mkdir -p $HOME/src

## Install `xdp-tools`.

cd $HOME/src
git clone -b v1.4.2 --depth 1 --recurse-submodules https://github.com/xdp-project/xdp-tools.git
cd xdp-tools/lib/libbpf/src
make -j$(nproc)
sudo DESTDIR=/ make install
cd ../../..
make clean
make -j$(nproc) libxdp
cd xdp-loader
make clean
make -j$(nproc)
sudo make install

## Install `lunatik`.

cd $HOME/src
git clone --recursive https://github.com/luainkernel/lunatik.git
cd lunatik
sudo -E make btf_install
make -j$(nproc)
sudo -E make install
sudo -E make examples_install

if ! grep -q KERNEL_VERSION $HOME/.bashrc; then
	echo 'export KERNEL_VERSION="$(uname -r)"' >> $HOME/.bashrc
fi

sudo rm -rf /lib/modules/$KERNEL_VERSION/kernel/zfs

## Install `dome`.

cd $HOME/src
BRANCH=""
if [ -n "$DOME_BRANCH" ]; then
        BRANCH="--branch $DOME_BRANCH"
fi
git clone --recursive https://github.com/ring0networks/dome.git --single-branch $BRANCH
cd dome
make -j$(nproc)
sudo -E make install

