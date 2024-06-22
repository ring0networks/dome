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

local xdp     = require("xdp")
local mailbox = require("mailbox")
local malware = require("dome/malware")
local unpack  = require("dome/unpack")

local action   = xdp.action
local unpacker = unpack.unpacker

function argparse(argument)
	local short = select(2, unpacker(argument, 0))
	return short(0), short(2)
end

local outbox
local function filter_hostname(packet, argument)
	local offset, length = argparse(argument)
	local str = select(3, unpacker(packet, offset))

	local request = str(0, length)
	local hostname = string.match(request, "Host:%s(.-)\r\n")

	local verdict = malware[hostname] and "DROP" or "PASS"
	outbox:send(verdict .. hostname)

	return action[verdict]
end

local function attacher(queue)
	outbox = mailbox.outbox(queue)
	xdp.attach(filter_hostname)
	print("[ring-0/dome] HOSTNAME filter attached")
end

print("[ring-0/dome] HOSTNAME filter loaded")
return attacher
