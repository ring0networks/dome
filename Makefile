# SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: GPL-2.0-only

INSTALL_PATH = /lib/modules/lua/dome
CP = cp -rp
RM = rm -f
MKDIR = mkdir -p -m 0755
INSTALL = install -o root -g root

DOME_MODULES = hook

EBPF_FILTERS = filter
EBPF_FILTERS_OBJS = ${EBPF_FILTERS:=.o}

CFLAGS=-DDOME_CONFIG_ROUTER

all: vmlinux.h ${EBPF_FILTERS_OBJS} config.lua blocklist

vmlinux.h:
	bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h

%.o: %.c
	clang -target bpf -Wall -O2 -c -g ${CFLAGS} $<

clean:
	${RM} vmlinux.h ${EBPF_FILTERS_OBJS} config.lua
	${RM} -r blocklist/

install: config.lua blocklist
	${MKDIR} ${INSTALL_PATH}
	${INSTALL} -m 0644 *.lua ${INSTALL_PATH}/
	${INSTALL} -m 0644 blocklist/*.lua ${INSTALL_PATH}/
	${CP} ${DOME_MODULES} ${INSTALL_PATH}

uninstall:
	${RM} -r ${INSTALL_PATH}

run: install
	lunatik reload
	xdp-loader load -m skb luaxdp0 ${EBPF_FILTERS_OBJS}
	lunatik spawn dome/daemon

stop:
	xdp-loader unload --all luaxdp0
	lunatik stop dome/daemon

namespace:
	./namespace.sh

config.lua:
	cat config.lua.example | sed 's/eth0/luaxdp0/g' > config.lua

blocklist:
	./blocklist.sh

