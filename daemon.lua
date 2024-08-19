--
-- SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
-- SPDX-License-Identifier: GPL-2.0-only
--

local lunatik = require("lunatik")
local thread  = require("thread")
local socket  = require("socket")
local inet    = require("socket.inet")
local linux   = require("linux")
local mailbox = require("mailbox")
local rcu     = require("rcu") -- used for lunatik.runtimes()
local data    = require("data")
local config  = require("dome/config")
local reply   = require("dome/reply")

local runtimes = lunatik.runtimes()

local shouldstop = thread.shouldstop

local telegraf = inet.udp()
function telegraf:push(message)
	self:sendto(message, inet.localhost, 8094)
end

local inbox = {
	notify = mailbox.inbox(config.mailbox_max),
	reply  = mailbox.inbox(config.mailbox_max)
}

local function dispatch(script, ...)
	if runtimes[script] then
		error(string.format("%s is already running", script))
	end

	local runtime = lunatik.runtime(script, false)
	thread.run(runtime, script, ...)
	runtimes[script] = runtime
end

local function daemon()
	print("[ring-0/dome] started")
	while (not shouldstop()) do
		local message = inbox.notify:receive()
		if message then
			telegraf:push(config.notify_header .. message)
		end
		local frame = inbox.reply:receive()
		if frame then
			local what, frame = frame:match('(%a*):(.*)')
			local packet = data.new(#frame)
			packet:setstring(0, frame)
			reply[what](packet)
		end
		if not message and not frame then
			linux.schedule(config.schedule_interval)
		end
	end
	print("[ring-0/dome] stopped")
end

dispatch("dome/filter", inbox.notify.queue, inbox.reply.queue)

return daemon

