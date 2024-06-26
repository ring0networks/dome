--
-- SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
-- SPDX-License-Identifier: GPL-2.0-only
--

local thread  = require("thread")
local socket  = require("socket")
local inet    = require("socket.inet")
local linux   = require("linux")
local mailbox = require("mailbox")
local filter  = require("dome/filter")

local shouldstop = thread.shouldstop

local telegraf = inet.udp()
telegraf:connect(inet.localhost, 8094)

local inbox = mailbox.inbox(100 * 1024)
__filters = { -- keep refs to avoid __gc()
	sni      = filter.new("sni", inbox.queue),
	hostname = filter.new("hostname", inbox.queue),
}

local header = 'https,host=ring-0.io,location=rj '

local function daemon()
	print("[ring-0/dome] started")
	while (not shouldstop()) do
		local message = inbox:receive()
		if message then
			local message = string.gsub(message, "(%u+)(%g+)", header .. 'domain="%2",action="%1"\n')
			telegraf:send(message)
		else
			linux.schedule(100)
		end
	end
	print("[ring-0/dome] stopped")
end

return daemon

