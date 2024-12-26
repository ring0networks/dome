--
-- SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
-- SPDX-License-Identifier: GPL-2.0-only
--

local linux     = require("linux")
local netfilter = require("netfilter")

local ETH_HLEN    = 14
local IPPROTO_TCP = 0x06

local mod = {}

mod.action = netfilter.action

local function parser(outbox, filter)
	return function (packet)
		local ihl = packet:getbyte(ETH_HLEN) & 0x0F
		local thoff = ihl * 4
		local proto = packet:getbyte(ETH_HLEN + 9)
		local doff = ((packet:getbyte(ETH_HLEN + thoff + 12) >> 4) & 0x0F) * 4
		local offset = ETH_HLEN + thoff + doff
		local headers = {
			smac = packet:getstring(6, 6),
			saddr = packet:getuint32(ETH_HLEN + 12),
			daddr = packet:getuint32(ETH_HLEN + 16),
			sport = linux.ntoh16(packet:getuint16(ETH_HLEN + thoff)),
			dport = linux.ntoh16(packet:getuint16(ETH_HLEN + thoff + 2))
		}

		if offset >= #packet or proto ~= IPPROTO_TCP then
			return mod.action.CONTINUE
		end

		return filter(packet, offset, headers, mod.action.CONTINUE, mod.action.DROP, outbox)
	end
end

function mod.attach(outbox, filter)
		netfilter.register{
			pf = netfilter.family.INET,
			hooknum = netfilter.inet_hooks.FORWARD,
			priority = netfilter.ip_priority.LAST,
			hook = parser(outbox, filter),
		}
end

return mod

