--
-- Copyright (C) 2024 Ring Zero Desenvolvimento de Software LTDA.
--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
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

