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

local runtimes = lunatik.runtimes()

local shouldstop = thread.shouldstop

local telegraf = inet.udp()
function telegraf:push(message)
	self:sendto(message, inet.localhost, 8094)
end

local inbox = mailbox.inbox(100 * 1024)

local header = 'http,host=ring-0.io,location=rj '

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
		local message = inbox:receive()
		if message then
			telegraf:push(header .. message)
		else
			linux.schedule(100)
		end
	end
	print("[ring-0/dome] stopped")
end

dispatch("dome/filter", inbox.queue)

return daemon

