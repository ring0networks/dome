--
-- SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
-- SPDX-License-Identifier: GPL-2.0-only
--

local xdp = require("xdp")

local mod = {}

mod.action = xdp.action

local function argparse(argument)
	return argument:getuint16(0),
	argument:getuint32(2),
	argument:getuint32(6),
	argument:getuint16(10),
	argument:getuint16(12),
	argument:getuint8(14)
end

local function parser(outbox, filter)
	return function (packet, argument)
		local offset, saddr, daddr, sport, dport, allow = argparse(argument)
		local smac = packet:getstring(6, 6)
		return filter(packet, offset, {
			smac = smac,
			saddr = saddr,
			daddr = daddr,
			sport = sport,
			dport = dport,
		}, allow, mod.action.DROP, outbox)
	end
end

function mod.attach(outbox, filter)
	xdp.attach(parser(outbox, filter))
end

return mod

