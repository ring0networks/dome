--
-- SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
-- SPDX-License-Identifier: GPL-2.0-only
--

local linux      = require("linux")
local runner     = require("lunatik.runner")
local thread     = require("thread")
local inet       = require("socket.inet")
local mailbox    = require("mailbox")
local data       = require("data")
local config     = require("dome/config")
local reply      = require("dome/reply")

local shouldstop = thread.shouldstop

local inbox = mailbox.inbox(config.mailbox_max)

local telegraf = inet.udp()
function telegraf:push(message)
	self:sendto(message, inet.localhost, 8094)
end

local function handle()
	local message = inbox:receive()
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

local function daemon()
	print("[ring-0/dome] started")
	while (not shouldstop()) do
		local ok, err = pcall(handle)
		if not ok then
			print(string.format("[ring-0/dome] error: %s", err))
			linux.schedule(100)
		end
	end
	print("[ring-0/dome] stopped")
end

runner.run("dome/filter", false):resume(inbox.queue, inbox.event)

return daemon

