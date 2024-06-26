--
-- SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
-- SPDX-License-Identifier: GPL-2.0-only
--

local xdp     = require("xdp")
local mailbox = require("mailbox")
local malware = require("dome/malware")
local unpack  = require("dome/unpack")

local action   = xdp.action
local unpacker = unpack.unpacker

local function offset(argument)
	return select(2, unpacker(argument, 0))(0)
end

local client_hello = 0x01
local handshake    = 0x16
local server_name  = 0x00

local session = 43
local max_extensions = 17

local outbox
local function filter_sni(packet, argument)
	local byte, short, str = unpacker(packet, offset(argument))

	if byte(0) ~= handshake or byte(5) ~= client_hello then
		return action.PASS
	end

	local cipher = (session + 1) + byte(session)
	local compression = cipher + 2 + short(cipher)
	local extension = compression + 3 + byte(compression)

	for i = 1, max_extensions do
		local data = extension + 4
		if short(extension) == server_name then
			local length = short(data + 3)
			local sni = str(data + 5, length)

			verdict = malware[sni] and "DROP" or "PASS"
			outbox:send(verdict .. sni)
			return action[verdict]
		end
		extension = data + short(extension + 2)
	end

	return action.PASS
end

local function attacher(queue)
	outbox = mailbox.outbox(queue)
	xdp.attach(filter_sni)
	print("[ring-0/dome] SNI filter attached")
end

print("[ring-0/dome] SNI filter loaded")
return attacher

