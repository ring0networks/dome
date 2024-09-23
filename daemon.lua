--
-- SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
-- SPDX-License-Identifier: GPL-2.0-only
--

local lunatik    = require("lunatik")
local thread     = require("thread")
local socket     = require("socket")
local inet       = require("socket.inet")
local mailbox    = require("mailbox")
local linux      = require("linux")
local data       = require("data")
local completion = require("completion")
local config     = require("dome/config")
local reply      = require("dome/reply")

local env = lunatik._ENV

local shouldstop = thread.shouldstop

local inbox = mailbox.inbox(config.mailbox_max)

local telegraf = inet.udp()
function telegraf:push(message)
	self:sendto(message, inet.localhost, 8094)
end

local function dispatch(script, ...)
	if env.runtimes[script] then
		error(string.format("%s is already running", script))
	end

	local args = {...}
	linux.percpu(function (cpu)
		local runtime = lunatik.runtime(script, false)
		runtime:resume(table.unpack(args))
		local name = cpu == 0 and script or script .. ':' .. cpu
		env.runtimes[name] = runtime
	end)
end

local function daemon()
	print("[ring-0/dome] started")
	while (not shouldstop()) do
		local ok, message = pcall(inbox.receive, inbox)
		if not ok then break end

		local header, body = message:match("^(%a*)|(.+)")
		if header == "notify" then
			telegraf:push(config.notify_header .. body)
		elseif header == "reply" then
			local what, frame = body:match('(%a*)|(.*)')
			local packet = data.new(#frame)
			packet:setstring(0, frame)
			reply[what](packet)
		else
			error("invalid message: %s", message)
		end
	end
	print("[ring-0/dome] stopped")
end

dispatch("dome/filter", inbox.queue, inbox.event)

return daemon

