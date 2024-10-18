# SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: GPL-2.0-only

INSTALL_PATH = /lib/modules/lua/dome
RM = rm -f
MKDIR = mkdir -p -m 0755
INSTALL = install -o root -g root

EBPF_FILTERS = filter
EBPF_FILTERS_OBJS = ${EBPF_FILTERS:=.o}

CFLAGS=-DDOME_CONFIG_ROUTER

.PHONY: config.lua

all: vmlinux.h ${EBPF_FILTERS_OBJS} config.lua blocklist

vmlinux.h:
	bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h

%.o: %.c
	clang -target bpf -Wall -O2 -c -g ${CFLAGS} $<

clean:
	${RM} vmlinux.h ${EBPF_FILTERS_OBJS} config.lua
	${RM} -r blocklist/
	./namespace.sh down

install: config.lua blocklist
	${MKDIR} ${INSTALL_PATH}
	${INSTALL} -m 0644 *.lua ${INSTALL_PATH}/
	${INSTALL} -m 0644 blocklist/*.lua ${INSTALL_PATH}/

uninstall:
	${RM} -r ${INSTALL_PATH}

run: install
	lunatik reload
	xdp-loader load -m skb ${LUAXDP_IFACE} ${EBPF_FILTERS_OBJS}
	lunatik spawn dome/daemon

stop:
	xdp-loader unload --all ${LUAXDP_IFACE}
	lunatik stop dome/daemon

namespace:
	./namespace.sh up

config.lua:
	cat config.lua.example | sed 's/eth0/${LUAXDP_IFACE}/g' > config.lua

blocklist:
	./blocklist.sh

