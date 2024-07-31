/*
* SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
* SPDX-License-Identifier: GPL-2.0-only
*/

#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x800;
const bit<8> IPPROTO_TCP = 6;

typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

header ethernet_t {
	macAddr_t dstAddr;
	macAddr_t srcAddr;
	bit<16>   etherType;
}

header ipv4_t {
	bit<4>    version;
	bit<4>    ihl;
	bit<8>    diffserv;
	bit<16>   totalLen;
	bit<16>   identification;
	bit<3>    flags;
	bit<13>   fragOffset;
	bit<8>    ttl;
	bit<8>    protocol;
	bit<16>   hdrChecksum;
	ip4Addr_t srcAddr;
	ip4Addr_t dstAddr;
}

header tcp_t {
	bit<16> srcPort;
	bit<16> dstPort;
	bit<32> seqNo;
	bit<32> ackNo;
	bit<4>  dataOffset;
	bit<3>  reserved;
	bit<1>  ns;
	bit<1>  cwr;
	bit<1>  ece;
	bit<1>  urg;
	bit<1>  ack;
	bit<1>  psh;
	bit<1>  rst;
	bit<1>  syn;
	bit<1>  fin;
	bit<16> window;
	bit<16> checksum;
	bit<16> urgentPtr;
}

struct metadata {}

struct headers {
	ethernet_t ethernet;
	ipv4_t     ipv4;
	tcp_t      tcp;
}

parser Ring0Parser(
	packet_in packet,
	out headers hdr,
	inout metadata meta,
	inout standard_metadata_t standard_metadata
) {
	state start {
		transition parse_ethernet;
	}

	state parse_ethernet {
		packet.extract(hdr.ethernet);
		transition select(hdr.ethernet.etherType) {
			TYPE_IPV4: parse_ipv4;
			default: accept;
		}
	}

	state parse_ipv4 {
		packet.extract(hdr.ipv4);
		transition select(hdr.ipv4.protocol) {
			IPPROTO_TCP: parse_tcp;
			default: accept;
		}
	}

	state parse_tcp {
		packet.extract(hdr.tcp);
		transition accept;
	}
}

control Ring0VerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {}
}

control Ring0Ingress(
	inout headers hdr,
	inout metadata meta,
	inout standard_metadata_t standard_metadata
) {
	action drop() {
		mark_to_drop(standard_metadata);
	}

	action forward(macAddr_t dstAddr, bit<9> port) {
		standard_metadata.egress_spec = port;
		hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
		hdr.ethernet.dstAddr = dstAddr;
		hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
	}

	table filter_tcp_psh {
		key = {
			standard_metadata.egress_spec: exact;
			hdr.tcp.dstPort: exact;
			hdr.tcp.psh: exact;
		}
		actions = {
			forward;
			drop;
			NoAction;
		}
		const default_action = NoAction;
	}

	apply {
		if (standard_metadata.ingress_port == 1) {
			filter_tcp_psh.apply();
		}
	}
}

control Ring0Egress(
	inout headers hdr,
	inout metadata meta,
	inout standard_metadata_t standard_metadata
) {
	apply {}
}

control Ring0ComputeChecksum(inout headers  hdr, inout metadata meta) {
	apply {
		update_checksum(
			hdr.ipv4.isValid(), {
			hdr.ipv4.version,
			hdr.ipv4.ihl,
			hdr.ipv4.diffserv,
			hdr.ipv4.totalLen,
			hdr.ipv4.identification,
			hdr.ipv4.flags,
			hdr.ipv4.fragOffset,
			hdr.ipv4.ttl,
			hdr.ipv4.protocol,
			hdr.ipv4.srcAddr,
			hdr.ipv4.dstAddr
		}, hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
	}
}

control Ring0Deparser(packet_out packet, in headers hdr) {
	apply {
		packet.emit(hdr.ethernet);
		packet.emit(hdr.ipv4);
		packet.emit(hdr.tcp);
	}
}

V1Switch(
	Ring0Parser(),
	Ring0VerifyChecksum(),
	Ring0Ingress(),
	Ring0Egress(),
	Ring0ComputeChecksum(),
	Ring0Deparser()
) main;

