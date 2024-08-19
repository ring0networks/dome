--
-- SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
-- SPDX-License-Identifier: GPL-2.0-only
--

local xdp     = require("xdp")
local mailbox = require("mailbox")
local pack    = require("dome/pack")
local config  = require("dome/config")

local unpacker = pack.unpacker

local policy = "PASS"

local format = string.format
local function log(fmt, ...)
	print(format("[ring-0/dome] " .. fmt, ...))
end

local function loadlists(lists)
	local result = {}
	for _, name in ipairs(lists) do
		result[name] = require("dome/" .. name)
	end
	return result
end

local allowlists = loadlists(config.allowlists)
local blocklists = loadlists(config.blocklists)

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

local reply = {
	[ 80] = "redirect",
	[443] = "reset"
}

local action = xdp.action

local function argparse(argument)
	return function (n)
		return argument:getuint16((n - 1) * 2)
	end
end

local function match(lists, domain, action)
	for reason, list in pairs(lists) do
		if list[domain] then
			return {reason = reason, action = action}
		end
	end
end

local function filter(outbox)
	return function (packet, argument)
		local arg = argparse(argument)
		local dport, offset, length = arg(1), arg(2), arg(3)
		local parser = parsers[dport]

		if not parser then
			log("filter was not found (dport = %d)", dport)
		else
			local verdict = {reason = "default", action = policy}
			local domain  = parser(packet, offset, length)
			if domain then
				verdict = match(allowlists, domain, "PASS") or
					match(blocklists, domain, "DROP") or verdict

				local message = format('domain="%s",dport="%d",action="%s",reason="%s"',
					domain, dport, verdict.action, verdict.reason)
				outbox.notify(message)

				if verdict.action == "DROP" then
					outbox.reply(reply[dport] .. ":" .. tostring(packet))
				end
			end
			return action[verdict.action]
		end
	end
end

local function sender(action, queue)
	return function (...)
		local outbox = mailbox.outbox(queue)
		local ok, err =  pcall(outbox.send, outbox, ...)
		if not ok then
			log("failed to %s: %s", action, err)
		end
	end
end

local function attacher(notify, reply)
	local outbox = {
		notify = sender('notify', notify),
		reply = sender('reply', reply),
	}
	xdp.attach(filter(outbox))
	log("filter attached")
end

log("filter loaded")
return attacher

