--
-- SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
-- SPDX-License-Identifier: GPL-2.0-only
--

local linux     = require("linux")
local netfilter = require("netfilter")
local config    = require("dome/config")

local ETH_HLEN    = 14
local IPPROTO_TCP = 0x06

local action = netfilter.action

local hook = {action = action}

local function parser(outbox, filter)
	return function (packet)
		local ihl = packet:getbyte(ETH_HLEN) & 0x0F
		local thoff = ihl * 4
		local proto = packet:getbyte(ETH_HLEN + 9)

		if proto ~= IPPROTO_TCP then
			return action.CONTINUE
		end

		local doff = ((packet:getbyte(ETH_HLEN + thoff + 12) >> 4) & 0x0F) * 4
		local offset = ETH_HLEN + thoff + doff
		local headers = {
			smac = packet:getstring(6, 6),
			saddr = packet:getuint32(ETH_HLEN + 12),
			daddr = packet:getuint32(ETH_HLEN + 16),
			sport = linux.ntoh16(packet:getuint16(ETH_HLEN + thoff)),
			dport = linux.ntoh16(packet:getuint16(ETH_HLEN + thoff + 2))
		}

		return offset >= #packet and action.CONTINUE or
			filter(packet, offset, headers, action.CONTINUE, action.DROP, outbox)
	end
end

function hook.attach(outbox, filter)
	local handler = {hook = parser(outbox, filter)}
	if config.netfilter == "bridge" then
		handler.pf = netfilter.family.BRIDGE
		handler.hooknum = netfilter.bridge_hooks.PRE_ROUTING
		handler.priority = netfilter.bridge_priority.FIRST
	else
		handler.pf = netfilter.family.INET
		handler.hooknum = netfilter.inet_hooks.FORWARD
		handler.priority = netfilter.ip_priority.LAST
	end

	netfilter.register(handler)
end

return hook

