#!/bin/sh
# SPDX-FileCopyrightText: (c) 2024-2025 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: GPL-2.0-only

if [ $# -lt 1 ] || [ $# -gt 2 ]
then
    printf "usage: %s <start|stop|restart|status> [bridge]\n" "$(basename $0)" >&2
    exit 1
fi

DOME_HOME="$(dirname $0)"

DOME_PREFIX=/lib/modules/lua/dome

if [ ! -e "$DOME_PREFIX" ]
then
    printf "dome is not installed.\n" >&2
    exit 2
fi

DOME_CONFIG="$DOME_PREFIX/config.lua"

DOME_FILTER=$(cd $DOME_PREFIX && lua -e "config = require('config') print(config.filter)")

DOME_IFACE=$(cd $DOME_PREFIX && lua -e "config = require('config') print(config.iface)")

[ -n "$2" ] && DOME_MODE="_$2"

dome_start() {
    sudo lunatik status | grep -q 'is not loaded' &&
        sudo lunatik load
    [ "$DOME_FILTER" = "xdp" ] &&
        sudo xdp-loader load -m skb $DOME_IFACE "$DOME_HOME/filter$DOME_MODE.o"
    sudo lunatik spawn dome/daemon > /dev/null
}

dome_stop() {
    [ "$DOME_FILTER" = "xdp" ] &&
        sudo xdp-loader unload --all $DOME_IFACE
    sudo lunatik stop dome/filter > /dev/null
    sudo lunatik stop dome/daemon > /dev/null
}

dome_status() {
    [ "$DOME_FILTER" = "xdp" ] &&
        printf "    dome: configured to use XDP on intarface %s\n" "$DOME_IFACE" ||
        printf "    dome: configured to use Netfilter\n" "$DOME_IFACE"

    list="$(sudo lunatik list)"
    [ -z "$list" ] && list="<none>"
    printf " lunatik: $list\n"
}

if [ "$1" = "start" ]
then
    dome_start
elif [ "$1" = "stop" ]
then
    dome_stop
elif [ "$1" = "restart" ]
then
    dome_stop
    dome_start
elif [ "$1" = "status" ]
then
    dome_status
else
    printf "invalid command: %s\n" "$1" >&2
    exit 3
fi
