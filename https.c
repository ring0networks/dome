/*
* SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
* SPDX-License-Identifier: GPL-2.0-only
*/

#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_endian.h>

extern int bpf_luaxdp_run(char *key, size_t key__sz, struct xdp_md *xdp_ctx, void *arg, size_t arg__sz) __ksym;

static char runtime[] = "dome/sni";

struct bpf_luaxdp_arg {
	__u16 offset;
} __attribute__((packed));

SEC("xdp")
int filter_https(struct xdp_md *ctx)
{
	struct bpf_luaxdp_arg arg;
	void *data_end = (void *)(long)ctx->data_end;
	void *data = (void *)(long)ctx->data;
	struct iphdr *ip = data + sizeof(struct ethhdr);

	if (ip + 1 > (struct iphdr *)data_end)
		goto pass;

	if (ip->protocol != IPPROTO_TCP)
		goto pass;

	struct tcphdr *tcp = (void *)ip + (ip->ihl * 4);
	if (tcp + 1 > (struct tcphdr *)data_end)
		goto pass;

	if (bpf_ntohs(tcp->dest) != 443 || !tcp->psh)
		goto pass;

	void *payload = (void *)tcp + (tcp->doff * 4);
	if (payload > data_end)
		goto pass;

	arg.offset = bpf_htons((__u16)(payload - data));

	int action = bpf_luaxdp_run(runtime, sizeof(runtime), ctx, &arg, sizeof(arg));
	return action < 0 ? XDP_PASS : action;
pass:
	return XDP_PASS;
}

char _license[] SEC("license") = "Dual MIT/GPL";

