--
-- SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
-- SPDX-License-Identifier: GPL-2.0-only
--

local linux = require("linux")

local ntoh16, ntoh32 = linux.ntoh16, linux.ntoh32
local hton16, hton32 = linux.hton16, linux.hton32

local pack = {}

function pack.unpacker(packet, base)
	base = base or 0

	local u8 = function (offset)
		return packet:getuint8(base + offset)
	end

	local be16 = function (offset)
		return ntoh16(packet:getuint16(base + offset))
	end

	local be32 = function (offset)
		return ntoh32(packet:getuint32(base + offset))
	end

	local str = function (offset, length)
		return packet:getstring(base + offset, length)
	end

	return str, u8, be16, be32
end

function pack.packer(packet, base)
	base = base or 0

	local u8 = function (offset, value)
		packet:setuint8(base + offset, value)
	end

	local be16 = function (offset, value)
		packet:setuint16(base + offset, hton16(value))
	end

	local be32 = function (offset, value)
		packet:setuint32(base + offset, hton32(value))
	end

	local str = function (offset, value)
		packet:setstring(base + offset, value)
	end

	return str, u8, be16, be32
end

return pack

