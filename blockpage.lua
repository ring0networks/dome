--
-- Copyright (C) 2024 Ring Zero Desenvolvimento de Software LTDA.
--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--

local data   = require("data")
local socket = require("socket")
local unpack = require("dome/unpack")

local PACKET    = socket.af.PACKET
local RAW       = socket.sock.RAW

local IPHDR     = 14
local RST       = 1 << 2
local ACK       = 1 << 4

local packer   = unpack.packer
local unpacker = unpack.unpacker

-- https://datatracker.ietf.org/doc/html/rfc1141
local function checksum(data, size)
	local sum = 0
	for i = 1, size, 2 do
		sum = sum + string.unpack(">I2", data, i)
	end
	if size % 2 == 1 then
		sum = sum + string.unpack("I1", data, size)
	end
	sum = sum & 0xffffffff
	while sum >> 16 ~= 0 do
		sum = (sum >> 16) + sum & 0xffff
	end
	return ~sum & 0xffff
end

local function ethhdr(packet)
	return {
		dst = packet:getstring(0, 6),
		src = packet:getstring(6, 6),
	}
end

local function iphdr(packet)
	local byte, short, _, str = unpacker(packet, IPHDR)
	return {
		ihl     = byte(0) & 0xf,
		tot_len = short(2), -- XXX wrong!
		ttl     = byte(8),
		saddr   = str(12, 4),
		daddr   = str(16, 4),
	}
end

-- https://datatracker.ietf.org/doc/html/rfc9293
local function tcphdr(packet)
	local ihl = packet:getbyte(IPHDR) & 0xf
	local base = IPHDR + ihl * 4
	local byte, short, int, _ = unpacker(packet, base)
	return {
		source  = short(0),
		dest    = short(2),
		seq     = int(4),
		ack_seq = int(8),
		doff    = byte(11) >> 4,
		flags   = byte(12),
		check   = short(16),
	}, base
end

local function edit_eth(packet)
	local eth = ethhdr(packet)
	packet:setstring(0, eth.src)
	packet:setstring(6, eth.dst)
end

local function edit_ip(packet)
	local ip = iphdr(packet, IPHDR)

	packet:setstring(IPHDR + 12, ip.daddr)
	packet:setstring(IPHDR + 16, ip.saddr)

	packet:setbyte(IPHDR + 10, 0)
	packet:setbyte(IPHDR + 11, 0)

	local size = ip.ihl * 4
	local header = packet:getstring(IPHDR, size)
	local sum = checksum(header, size)

	packet:setbyte(IPHDR + 10, (sum & 0xff00) >> 8)
	packet:setbyte(IPHDR + 11, (sum & 0x00ff))
end

local function edit_tcp(packet, flags)
	local ip, tcp, base = iphdr(packet), tcphdr(packet)

	print(string.format("[TCP/1] %d -> %d, seq=%d, ack=%d, doff=%d, flags=%x, check=%x, ihl=%d, tot=%d",
		tcp.source, tcp.dest, tcp.seq, tcp.ack_seq, tcp.doff * 4, tcp.flags, tcp.check, ip.ihl, ip.tot_len))

	local setbyte, setshort, setint, setstring = packer(packet, base)

	-- XXX create pseudo header to calculate the tcp checksum

	setshort(0, tcp.dest)
	setshort(2, tcp.source)
	setint(4, tcp.ack_seq)
	setint(8, tcp.seq + 1)
	setbyte(12, flags)

	-- ip, tcp, _ = iphdr(packet), tcphdr(packet)
end

local function edit(packet, flags)
	edit_tcp(packet, flags or 0)
	edit_ip(packet)
	edit_eth(packet)
end

local function reply(packet)
end

local blockpage = {
	checksum = checksum,
	edit = edit,
	ethhdr = ethhdr,
	iphdr = iphdr,
	tcphdr = tcphdr,
}

function blockpage.https(packet)
	edit(packet, RST | ACK)
	reply(packet)
end

return blockpage
