# SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: GPL-2.0-only

ETH1 = eth1
ETH2 = eth2

EBPF_FILTERS = redirect
EBPF_FILTERS_OBJS = $(EBPF_FILTERS:=.o)

all: vmlinux.h $(EBPF_FILTERS_OBJS)

vmlinux.h:
	bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h

%.o: %.c
	clang -target bpf -Wall -O2 -c -g $<

start:
	sudo xdp-loader load -m skb $(ETH1) $(EBPF_FILTERS_OBJS)
	sudo xdp-loader load -m skb $(ETH2) $(EBPF_FILTERS_OBJS)
	./config

status:
	sudo xdp-loader status
	sudo bpftool prog tracelog

stop:
	sudo xdp-loader unload --all $(ETH1)
	sudo xdp-loader unload --all $(ETH2)

clean:
	$(RM) vmlinux.h $(EBPF_FILTERS_OBJS)

