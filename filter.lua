--
-- SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
-- SPDX-License-Identifier: GPL-2.0-only
--

local linux   = require("linux")
local xdp     = require("xdp")
local mailbox = require("mailbox")
local malware = require("dome/malware")

local policy = "PASS"

local format = string.format
local function log(fmt, ...)
	print(format("[ring-0/dome] " .. fmt, ...))
end

local ntoh16 = linux.ntoh16
local function unpacker(packet, base)
	local u8 = function (offset)
		return packet:getuint8(base + offset)
	end

	local be16 = function (offset)
		return ntoh16(packet:getuint16(base + offset))
	end

	local str = function (offset, length)
		return packet:getstring(base + offset, length)
	end

	return str, u8, be16
end

local function hostname(packet, offset, length)
	local str = unpacker(packet, offset)
	local request = str(0, length)
	return string.match(request, "Host:%s(.-)\r\n")
end

local function sni(packet, offset)
	local str, u8, be16 = unpacker(packet, offset)

	local client_hello = 0x01
	local handshake    = 0x16
	local server_name  = 0x00

	local session = 43
	local max_extensions = 17

	if u8(0) ~= handshake or u8(5) ~= client_hello then
		return
	end

	local cipher = (session + 1) + u8(session)
	local compression = cipher + 2 + be16(cipher)
	local extension = compression + 3 + u8(compression)

	for i = 1, max_extensions do
		local data = extension + 4
		if be16(extension) == server_name then
			local length = be16(data + 3)
			return str(data + 5, length)
		end
		extension = data + be16(extension + 2)
	end
end

local parsers = {
	[ 80] = hostname,
	[443] = sni,
}

local function filter(outbox)
	local action = xdp.action

	local function argparse(argument)
		return function (n)
			return argument:getuint16((n - 1) * 2)
		end
	end

	return function (packet, argument)
		local arg = argparse(argument)
		local dport, offset, length = arg(1), arg(2), arg(3)
		local parser = parsers[dport]

		if not parser then
			log("filter was not found (dport = %d)", dport)
		else
			local verdict = policy
			local domain  = parser(packet, offset, length)
			if domain then
				verdict = malware[domain] and "DROP" or verdict
				outbox:send(format('domain="%s",dport="%d",action="%s"', domain, dport, verdict))
			end
			return action[verdict]
		end
	end
end

local function attacher(queue)
	local outbox = mailbox.outbox(queue)
	xdp.attach(filter(outbox))
	log("filter attached")
end

log("filter loaded")
return attacher

