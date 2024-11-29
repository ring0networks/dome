--
-- SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
-- SPDX-License-Identifier: GPL-2.0-only
--

local xdp     = require("xdp")
local nf      = require("netfilter")
local linux   = require("linux")
local mailbox = require("mailbox")
local pack    = require("dome/pack")
local config  = require("dome/config")

local ETH_HLEN    = 14
local IPPROTO_TCP = 0x06

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

local action = config.filter == "nf" and nf.action or xdp.action

local action_name = {}
for name, action in pairs(action) do
	action_name[action] = string.lower(name)
end

local function argparse(argument)
	return argument:getuint16(0),
		argument:getuint16(2),
		argument:getuint8(4)
end

local function match(lists, domain, action)
	for reason, list in pairs(lists) do
		if list[domain] then
			return {reason = reason, action = action}
		end
	end
end

local function filter(packet, offset, dport, allow, deny, outbox)
	local policy = config.policy == "allow" and allow or deny
	local verdict = {reason = "default", action = policy}

	local parser = parsers[dport]
	if not parser then
		log("filter was not found (dport = %d)", dport)
	else
		local domain  = parser(packet, offset)
		if domain then
			verdict = match(allowlists, domain, allow) or
				match(blocklists, domain, deny) or verdict

			local message = format('domain="%s",dport="%d",action="%s",reason="%s"',
				domain, dport, action_name[verdict.action], verdict.reason)
			outbox.notify(message)

			if verdict.action == deny then
				outbox.reply(reply[dport] .. "|" .. tostring(packet))
			end
		end
	end

	return verdict.action
end

local function filter_netfilter(outbox)
	return function (packet)
		local ihl = packet:getbyte(ETH_HLEN) & 0x0F
		local thoff = ihl * 4
		local proto = packet:getbyte(ETH_HLEN + 9)
		local doff = ((packet:getbyte(ETH_HLEN + thoff + 12) >> 4) & 0x0F) * 4
		local dport = linux.ntoh16(packet:getuint16(ETH_HLEN + thoff + 2))
		local offset = ETH_HLEN + thoff + doff

		if offset >= #packet or proto ~= IPPROTO_TCP then
			return action.CONTINUE
		end

		return filter(packet, offset, dport, action.CONTINUE, action.DROP, outbox)
	end
end

local function filter_xdp(outbox)
	return function (packet, argument)
		local dport, offset, allow = argparse(argument)
		return filter(packet, offset, dport, allow, action.DROP, outbox)
	end
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

	if config.filter == "nf" then
		nf.register{
			pf = nf.family.INET,
			hooknum = nf.inet_hooks.FORWARD,
			priority = nf.ip_priority.LAST,
			hook = filter_netfilter(outbox),
		}
	elseif config.filter == "xdp" then
		xdp.attach(filter_xdp(outbox))
	else
		error("invalid filter: %s", config.filter)
	end

	log("filter attached: %s", config.filter)
end

log("filter loaded")
return attacher

