/*
* SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
* SPDX-License-Identifier: GPL-2.0-only
*/

#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_endian.h>

#define ETH_P_IP 0x0800
#define ETH_ALEN 6

#define memcmp __builtin_memcmp
#define memcpy __builtin_memcpy

static const u32 eth1 = 3;
static const u32 eth2 = 4;

static const u8 macaddr_gw1[ETH_ALEN]  = {0x08, 0x00, 0x27, 0xb0, 0x90, 0x8f};
static const u8 macaddr_gw2[ETH_ALEN]  = {0x08, 0x00, 0x27, 0xca, 0x8c, 0x88};
static const u8 macaddr_cli[ETH_ALEN]  = {0x08, 0x00, 0x27, 0x65, 0xdd, 0x94};
static const u8 macaddr_dome[ETH_ALEN] = {0x08, 0x00, 0x27, 0xa2, 0xee, 0xcc};

SEC("xdp")
int redirect(struct xdp_md *ctx)
{
	void *data = (void *)(long)ctx->data;
	void *data_end = (void *)(long)ctx->data_end;
	struct ethhdr *eth = data;
	struct iphdr *ip = data + sizeof(struct ethhdr);

	if (ip + 1 > (struct iphdr *)data_end)
		goto pass;

	if (ip->protocol != IPPROTO_TCP)
		goto pass;

	struct tcphdr *tcp = (void *)ip + (ip->ihl * 4);
	if (tcp + 1 > (struct tcphdr *)data_end)
		goto pass;

	if (memcmp(eth->h_source, macaddr_dome, ETH_ALEN) == 0) {
		if (bpf_ntohs(tcp->source) == 80 || bpf_ntohs(tcp->source) == 443) {
			memcpy(eth->h_source, macaddr_gw1, ETH_ALEN);
			memcpy(eth->h_dest, macaddr_cli, ETH_ALEN);
			return bpf_redirect(eth1, 0);
		}
	}
	else if (tcp->psh && (bpf_ntohs(tcp->dest) == 80 || bpf_ntohs(tcp->dest) == 443)) {
		memcpy(eth->h_source, macaddr_gw2, ETH_ALEN);
		memcpy(eth->h_dest, macaddr_dome, ETH_ALEN);
		return bpf_redirect(eth2, 0);
	}
pass:
	return XDP_PASS;
}

char _license[] SEC("license") = "GPL";

