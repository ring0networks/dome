/*
* SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
* SPDX-License-Identifier: GPL-2.0-only
*/

#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_endian.h>

#define ETH_ALEN 6

#define memcpy __builtin_memcpy

extern int bpf_luaxdp_run(char *key, size_t key__sz, struct xdp_md *xdp_ctx, void *arg, size_t arg__sz) __ksym;

static char runtime[] = "dome/filter";

struct bpf_luaxdp_arg {
	__u16 dport;
	__u16 offset;
	__u16 length;
} __attribute__((packed));

#ifdef DOME_MODE_ROUTER
static inline int default_action(void *data)
{
	return XDP_PASS;
}
#else
static inline int default_action(void *data)
{
	unsigned char tmp[ETH_ALEN];
	struct ethhdr *eth = data;

	memcpy(tmp, eth->h_dest, ETH_ALEN);
	memcpy(eth->h_dest, eth->h_source, ETH_ALEN);
	memcpy(eth->h_source, tmp, ETH_ALEN);

	return XDP_TX;
}
#endif

SEC("xdp")
int filter(struct xdp_md *ctx)
{
	struct bpf_luaxdp_arg arg;
	void *data_end = (void *)(long)ctx->data_end;
	void *data = (void *)(long)ctx->data;
	struct iphdr *ip = data + sizeof(struct ethhdr);

	if (ip + 1 > (struct iphdr *)data_end)
		return XDP_DROP;

	if (ip->protocol != IPPROTO_TCP)
		goto end;

	struct tcphdr *tcp = (void *)ip + (ip->ihl * 4);
	if (tcp + 1 > (struct tcphdr *)data_end)
		goto end;

	__u16 dport = bpf_ntohs(tcp->dest);
	if ((dport != 80 && dport != 443) || !tcp->psh)
		goto end;

	void *payload = (void *)tcp + (tcp->doff * 4);
	if (payload > data_end)
		goto end;

	arg.dport = dport;
	arg.offset = (__u16)(payload - data);
	arg.length = (__u16)(data_end - payload);

	int action = bpf_luaxdp_run(runtime, sizeof(runtime), ctx, &arg, sizeof(arg));
	if (action >= 0 && action != XDP_PASS) {
		return action;
	}
end:
	return default_action(data);
}

char _license[] SEC("license") = "GPL";

