--
-- SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
-- SPDX-License-Identifier: GPL-2.0-only
--

local xdp     = require("xdp")
local mailbox = require("mailbox")
local malware = require("dome/malware")
local unpack  = require("dome/unpack")

local action   = xdp.action
local unpacker = unpack.unpacker

function argparse(argument)
	local short = select(2, unpacker(argument, 0))
	return short(0), short(2)
end

local outbox
local function filter_hostname(packet, argument)
	local offset, length = argparse(argument)
	local str = select(3, unpacker(packet, offset))

	local request = str(0, length)
	local hostname = string.match(request, "Host:%s(.-)\r\n")

	local verdict = malware[hostname] and "DROP" or "PASS"
	outbox:send(verdict .. hostname)

	return action[verdict]
end

local function attacher(queue)
	outbox = mailbox.outbox(queue)
	xdp.attach(filter_hostname)
	print("[ring-0/dome] HOSTNAME filter attached")
end

print("[ring-0/dome] HOSTNAME filter loaded")
return attacher
