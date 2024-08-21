/*
* SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
* SPDX-License-Identifier: GPL-2.0-only
*/

#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_endian.h>

#define ETH_ALEN 6

#define memcmp __builtin_memcmp
#define memcpy __builtin_memcpy

struct {
    __uint(type, BPF_MAP_TYPE_HASH);
    __uint(max_entries, 32);
    __type(key, char[8]);
    __type(value, u8[ETH_ALEN]);
} macaddr_map SEC(".maps");

struct {
    __uint(type, BPF_MAP_TYPE_DEVMAP);
    __uint(max_entries, 8);
    __type(key, int);
    __type(value, int);
} ifindex_map SEC(".maps");

typedef struct redirect_config_s {
	struct {
		u8 *gateway1;
		u8 *gateway2;
		u8 *client;
		u8 *dome;
	} macaddr;
} redirect_config_t;

#define REDIRECT_CONFIG_CHECK(attr, map, key) do {		\
	(attr) = bpf_map_lookup_elem((map), (key));		\
	if ((attr) == NULL) {					\
		bpf_printk("missing configuration: %s", key);	\
		return false;					\
	}							\
} while(0)

static bool redirect_config(redirect_config_t *config)
{
	REDIRECT_CONFIG_CHECK(config->macaddr.gateway1, &macaddr_map, "gateway1");
	REDIRECT_CONFIG_CHECK(config->macaddr.gateway2, &macaddr_map, "gateway2");
	REDIRECT_CONFIG_CHECK(config->macaddr.client,   &macaddr_map, "client  ");
	REDIRECT_CONFIG_CHECK(config->macaddr.dome,     &macaddr_map, "dome    ");
	return true;
}

SEC("xdp")
int redirect(struct xdp_md *ctx)
{
	void *data = (void *)(long)ctx->data;
	void *data_end = (void *)(long)ctx->data_end;
	struct ethhdr *eth = data;
	struct iphdr *ip = data + sizeof(struct ethhdr);
	redirect_config_t config;

	if (ip + 1 > (struct iphdr *)data_end)
		goto pass;

	if (ip->protocol != IPPROTO_TCP)
		goto pass;

	struct tcphdr *tcp = (void *)ip + (ip->ihl * 4);
	if (tcp + 1 > (struct tcphdr *)data_end)
		goto pass;

	if(!redirect_config(&config))
		goto pass;

	if (memcmp(eth->h_source, config.macaddr.dome, ETH_ALEN) == 0) {
		if (bpf_ntohs(tcp->source) == 80 || bpf_ntohs(tcp->source) == 443) {
			memcpy(eth->h_source, config.macaddr.gateway1, ETH_ALEN);
			memcpy(eth->h_dest, config.macaddr.client, ETH_ALEN);
			return bpf_redirect_map(&ifindex_map, 1, 0);
		}
	}
	else if (tcp->psh && (bpf_ntohs(tcp->dest) == 80 || bpf_ntohs(tcp->dest) == 443)) {
		memcpy(eth->h_source, config.macaddr.gateway2, ETH_ALEN);
		memcpy(eth->h_dest, config.macaddr.dome, ETH_ALEN);
		return bpf_redirect_map(&ifindex_map, 2, 0);
	}
pass:
	return XDP_PASS;
}

char _license[] SEC("license") = "GPL";

