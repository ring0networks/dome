#!/usr/bin/env bash
# SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: GPL-2.0-only
set -o pipefail

# Define the script name and description
SCRIPT_NAME=$(basename "$0")
DESCRIPTION="Either create or delete internal namespace to be used with luaxdp"

# Define the default value and the possible values
VALUES=("up" "down")

# set gateway interface
[ -z "$LUAXDP_GW" ] && LUAXDP_GW=$(ip r | awk 'NR ==1 {print $5}')

function enable_namespace() {
  sysctl -w net.ipv4.ip_forward=1

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
}

function disable_namespace() {
  iptables -D FORWARD -o $LUAXDP_GW -i luaxdp0 -j ACCEPT
  iptables -D FORWARD -i $LUAXDP_GW -o luaxdp0 -j ACCEPT
  iptables -t nat -D POSTROUTING -s 10.0.0.2/24 -o $LUAXDP_GW -j MASQUERADE

  ip netns del luaxdp
  ip link del luaxdp0
  rm -rf /etc/netns/luaxdp
  sysctl -w net.ipv4.ip_forward=0
}

# Parse input parameter
if [ "$1" ]; then
  INPUT_PARAM="$1"
  case "$INPUT_PARAM" in
    "${VALUES[0]}" | "${VALUES[1]}")
      # Perform the desired action based on the input parameter
      if [ "$INPUT_PARAM" = "up" ]; then
        enable_namespace
      elif [ "$INPUT_PARAM" = "down" ]; then
        disable_namespace
      fi
      ;;
    *)
      echo "Invalid input parameter: '$INPUT_PARAM'. Expected 'up' or 'down'."
      exit 1
      ;;
  esac
else
  echo "Error: Missing input parameter."
  exit 1
fi
