--
-- SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
-- SPDX-License-Identifier: GPL-2.0-only
--

local xdp = require("xdp")

local mod = {}

mod.action = xdp.action

local function argparse(argument)
	return argument:getuint16(0),       -- offset
		argument:getuint8(2),       -- version
		argument:getstring(3, 16),  -- saddr
		argument:getstring(19, 16), -- daddr
		argument:getuint16(35),     -- sport
		argument:getuint16(37),     -- dport
		argument:getuint8(39)       -- allow
end

local function parser(outbox, filter)
	return function (packet, argument)
		local offset, version, saddr, daddr, sport, dport, allow = argparse(argument)
		local smac = packet:getstring(6, 6)
		return filter(packet, offset, {
			version = version,
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

