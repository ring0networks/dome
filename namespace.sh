#!/bin/sh
# SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: GPL-2.0-only

export LUAXDP_GW=enp0s1 # replace it with your gateway interface
echo 1 > /proc/sys/net/ipv4/ip_forward
ip netns add luaxdp
ip netns exec luaxdp ip link set lo up
ip link add luaxdp0 type veth peer name luaxdp1
ip link set luaxdp1 netns luaxdp
ip addr add 10.0.0.1/24 dev luaxdp0
ip netns exec luaxdp ip addr add 10.0.0.2/24 dev luaxdp1
ip link set luaxdp0 up
ip netns exec luaxdp ip link set luaxdp1 up
iptables -A FORWARD -o $LUAXDP_GW -i luaxdp0 -j ACCEPT
iptables -A FORWARD -i $LUAXDP_GW -o luaxdp0 -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.0.0.2/24 -o $LUAXDP_GW -j MASQUERADE
ip netns exec luaxdp ip route add default via 10.0.0.1
mkdir -p /etc/netns/luaxdp
echo "nameserver 1.1.1.1" > /etc/netns/luaxdp/resolv.conf
echo 'alias ns="sudo ip netns exec luaxdp su - $USER"' > .nsrc
printf "# usage:\n$ source .nsrc\n$ ns\n$ curl https://wheel.to\n"

