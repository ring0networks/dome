--
-- SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
-- SPDX-License-Identifier: GPL-2.0-only
--

local mailbox = require("mailbox")
local pack    = require("dome/pack")
local hook    = require("dome/hook")
local config  = require("dome/config")

local unpacker = pack.unpacker

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

local function hostname(packet, offset)
	local str = unpacker(packet, offset)
	local request = str(0)
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

local function match(lists, domain, action)
	local i = 1
	repeat
		local subdomain = domain:sub(i)
		i = select(2, domain:find("%.%w", i))

		for reason, list in pairs(lists) do
			if list[subdomain] then
				return {reason = reason, action = action}
			end
		end
	until not i
end

local function mac_ntoa(mac)
	local ret = {}
	for i = 1, 6 do
		table.insert(ret, string.format("%02x", string.byte(mac, i)))
	end
	return table.concat(ret, ":")
end

local function inet_ntoa(addr)
	return string.format("%d.%d.%d.%d",
		addr & 0xFF,
		(addr >>  8) & 0xFF,
		(addr >> 16) & 0xFF,
		(addr >> 24) & 0xFF)
end

local function encode(message)
	local result = {}
	for key, value in pairs(message) do
		table.insert(result, tostring(key) .. "=\"" .. tostring(value) .. "\"")
	end
	return table.concat(result, ",")
end

local function filter(packet, offset, headers, allow, deny, outbox)
	local policy = config.policy == "allow" and allow or deny
	local verdict = {reason = "default", action = policy}

	local parser = parsers[headers.dport]
	if not parser then
		return allow
	end

	local ok, domain = pcall(parser, packet, offset)
	if not ok then
		domain = 'unknown'
		verdict.reason = 'error'
		verdict.action = config.deny_on_error and deny or allow
	elseif domain then
		verdict = match(allowlists, domain, allow) or
		match(blocklists, domain, deny) or verdict
	end

	if domain then
		if verdict.action == deny then
			outbox.reply(reply[headers.dport] .. "|" .. tostring(packet))
		end

		outbox.notify(encode{
			domain = domain,
			smac = mac_ntoa(headers.smac),
			saddr = inet_ntoa(headers.saddr),
			daddr = inet_ntoa(headers.daddr),
			sport = headers.sport,
			dport = headers.dport,
			action = hook.action_name[verdict.action],
			reason = verdict.reason
		})
	end

	return verdict.action
end

local function sender(channel, queue, event)
	local outbox = mailbox.outbox(queue, event)

	return function (message)
		local ok, err = pcall(outbox.send, outbox, channel .. '|' .. message)
		if not ok then
			log("failed to %s: %s", channel, err)
		end
	end
end

local function attacher(queue, event)
	local outbox = {
		notify = sender("notify", queue, event),
		reply = sender("reply", queue, event)
	}

	hook.attach(outbox, filter)

	log("filter attached: %s", config.filter)
end

log("filter loaded")
return attacher

