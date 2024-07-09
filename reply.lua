--
-- SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
-- SPDX-License-Identifier: GPL-2.0-only
--

local data   = require("data")
local linux  = require("linux")
local socket = require("socket")
local pack   = require("dome/pack")
local config = require("dome/config")

local PACKET = socket.af.PACKET
local RAW    = socket.sock.RAW

local ETH_HLEN  = 14
local ETH_P_ALL = 0x0003

local IPPROTO_TCP = 0x06

local RST = 1 << 2
local ACK = 1 << 4

local packer   = pack.packer
local unpacker = pack.unpacker

local net = {}

function net.checksum(data, offset, length)
	local offset = offset or 0
	local length = length or #data - offset
	local _, u8, be16 = unpacker(data, offset)
	local sum = 0

	for pos = 0, length - 1, 2 do
		sum = sum + be16(pos)
	end
	if length % 2 == 1 then
		sum = sum + u8(length - 1)
	end
	sum = sum & 0xffffffff
	while sum >> 16 ~= 0 do
		sum = (sum >> 16) + sum & 0xffff
	end

	return ~sum & 0xffff
end

function net.ethhdr(packet)
	local getstr, _, getbe16 = unpacker(packet)
	return {
		dst     = getstr(0, 6),
		src     = getstr(6, 6),
		ethtype = getbe16(12),
	}
end

function net.iphdr(packet)
	local getstr, getu8, getbe16, getbe32 = unpacker(packet, ETH_HLEN)
	return {
		version  = getu8(0) >> 4,
		ihl      = getu8(0) & 0xf,
		tos      = getu8(1),
		tot_len  = getbe16(2),
		id       = getbe16(4),
		frag_off = getbe16(6),
		ttl      = getu8(8),
		protocol = getu8(9),
		check    = getbe16(10),
		saddr    = getbe32(12),
		daddr    = getbe32(16),
	}
end

function net.tcphdr(packet)
	local ihl = packet:getbyte(ETH_HLEN) & 0xf
	local offset = ETH_HLEN + ihl * 4
	local _, getu8, getbe16, getbe32 = unpacker(packet, offset)
	return {
		source  = getbe16(0),
		dest    = getbe16(2),
		seq     = getbe32(4),
		ack_seq = getbe32(8),
		doff    = getu8(12) >> 4,
		flags   = getu8(13),
		window  = getbe16(14),
		check   = getbe16(16),
	}, offset
end

function net.pseudohdr(ip, tcp)
	local pseudo = data.new(12 + tcp.doff * 4)
	local _, setu8, setbe16, setbe32 = packer(pseudo)

	setbe32(0, ip.saddr)
	setbe32(4, ip.daddr)
	setu8(8, 0)
	setu8(9, IPPROTO_TCP)
	setbe16(10, tcp.doff * 4)

	return pseudo
end

function net.tcp_checksum(packet)
	local ip, tcp, offset = net.iphdr(packet), net.tcphdr(packet)
	local pseudo = net.pseudohdr(ip, tcp)
	pseudo:setstring(12, packet:getstring(offset, tcp.doff * 4))
	return net.checksum(pseudo)
end

local edit = {}

function edit.eth(packet)
	local setstr, _, setbe16 = packer(packet, 0)
	local eth = net.ethhdr(packet)

	setstr(0, eth.src)
	setstr(6, eth.dst)
	setbe16(12, eth.ethtype)
end

function edit.ip(packet, tcp_len)
	local _, setu8, setbe16, setbe32 = packer(packet, ETH_HLEN)
	local ip = net.iphdr(packet, ETH_HLEN)
	local size = ip.ihl * 4

	setbe16(2, size + tcp_len) -- tot_len = 40
	setbe16(4, 0)              -- id = 0
	setbe16(6, 0)              -- frag_off = 0
	setbe32(12, ip.daddr)      -- saddr = daddr
	setbe32(16, ip.saddr)      -- daddr = saddr
	setbe16(10, 0)             -- checksum = 0
	setbe16(10, net.checksum(packet, ETH_HLEN, size))
end

function edit.tcp(packet, flags)
	local ip, tcp, offset = net.iphdr(packet), net.tcphdr(packet)
	local _, setu8, setbe16, setbe32 = packer(packet, offset)
	setbe16(0, tcp.dest)     -- source = dest
	setbe16(2, tcp.source)   -- dest = source
	setbe32(4, tcp.ack_seq)  -- seq = ack_seq
	setbe32(8, tcp.seq + 1)  -- ack_seq = seq + 1
	setu8(12, 5 << 4)        -- doff = 5
	setu8(13, flags)         -- flags = flags
	setbe16(16, 0)           -- checksum = 0
	setbe16(16, net.tcp_checksum(packet))
end

function edit.packet(packet, flags)
	edit.tcp(packet, flags or 0)
	edit.ip(packet, 20)
	edit.eth(packet)
end

local socket = socket.new(PACKET, RAW, ETH_P_ALL)
local ifindex = linux.ifindex(config.iface)

local function send(packet)
	local frame = packet:getstring(0, ETH_HLEN + 40)
	socket:send(frame, ifindex)
end

local reply = {}

function reply.rst(packet)
	edit.packet(packet, RST | ACK)
	send(packet)
end

return reply

