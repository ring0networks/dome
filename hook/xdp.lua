--
-- SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
-- SPDX-License-Identifier: GPL-2.0-only
--

local xdp = require("xdp")

local mod = {}

mod.action = xdp.action

local function argparse(argument)
	return argument:getuint16(0),
	argument:getuint16(2),
	argument:getuint8(4)
end

local function parser(outbox, filter)
	return function (packet, argument)
		local dport, offset, allow = argparse(argument)
		return filter(packet, offset, dport, allow, mod.action.DROP, outbox)
	end
end

function mod.attach(outbox, filter)
	xdp.attach(parser(outbox, filter))
end

return mod

