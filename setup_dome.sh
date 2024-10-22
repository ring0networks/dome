#!/bin/sh
sudo sysctl -w net.ipv4.ip_forward=1

sudo iptables -D FORWARD -o $LUAXDP_GW -i $LUAXDP_IFACE -j ACCEPT
sudo iptables -D FORWARD -i $LUAXDP_GW -o $LUAXDP_IFACE -j ACCEPT

sudo iptables -t nat -A POSTROUTING -o $LUAXDP_GW -j MASQUERADE
