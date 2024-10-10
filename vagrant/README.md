# Dome VM

## Installation

1. Install [`vagrant`](https://developer.hashicorp.com/vagrant/docs/installation) on your system.
2. On Linux, install your favorite provider: `virtualbox`, `libvirt`, etc.
  - Eg: `sudo apt install virtualbox libvirt libvirt-daemon libvirt-daemon-system libvirt-clients bridge-utils virt-manager qemu-kvm`
3. Run `make <provider>`, where the possible providers are `virtualbox`, `libvirt` and `hyperv` (on Windows).
4. Log in, either via SSH or via `vagrant ssh`; user `dome` has password `dome`.

