--
-- SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
-- SPDX-License-Identifier: GPL-2.0-only
--

local unpack = {}

function unpack.unpacker(packet, base)
	local byte = function (offset)
		return packet:getbyte(base + offset)
	end

	local short = function (offset)
		local offset = base + offset
		return packet:getbyte(offset) << 8 | packet:getbyte(offset + 1)
	end

	local str = function (offset, length)
		return packet:getstring(base + offset, length)
	end

	return byte, short, str
end

return unpack

