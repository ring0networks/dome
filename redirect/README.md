
# Network Setup

## VirtualBox

- Host-only Network
  - vboxnet0, 192.168.56.1/24, dhcpd=enable

- Internal Networks
  - intnet (10.0.5.0/24)
  - fwnet (10.0.6.0/24)

### Gateway

- Hostname: gateway
- Network
  - eth0: (WAN/bridge to wifi)
  - eth1: 10.0.5.1/24 08:00:27:b0:90:8f (LAN/intnet)
  - eth2: 10.0.6.1/24 08:00:27:ca:8c:88 (LAN/fwnet)

### Client

- Hostname: client
- Network
  - eth0: 10.0.5.10/24 08:00:27:65:dd:94 (LAN/intnet)
  - eth1: (LAN/vboxnet0)

### Dome

- Hostname: dome
- Network
  - eth0: 10.0.6.10/24 08:00:27:a2:ee:cc (LAN/fwnet)
  - eth1: (LAN/vboxnet0)

## Configuration

To load the configuration into the eBPF program, first edit the `config` file at the top, setting the MAC addresses and ifindexes (you can obtain interface indexes using `ip link show`) according to your needs. Once configured, run:

```sh
./config
```

