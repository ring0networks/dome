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

local unpack = {}

function unpack.unpacker(packet, base)
	base = base or 0

	local byte = function (offset)
		return packet:getbyte(base + offset)
	end

	local short = function (offset)
		local offset = base + offset
		return packet:getbyte(offset) << 8 | packet:getbyte(offset + 1)
	end

	local int = function (offset)
		local offset = base + offset
		return packet:getbyte(offset) << 24 | 
			packet:getbyte(offset + 1) << 16 | 
			packet:getbyte(offset + 2) << 8 | 
			packet:getbyte(offset + 3)
	end

	local str = function (offset, length)
		return packet:getstring(base + offset, length)
	end

	return byte, short, int, str
end

function unpack.packer(packet, base)
	base = base or 0

	local byte = function (offset, value)
		packet:setbyte(base + offset, value)
	end

	local short = function (offset, value)
		packet:setbyte(base + offset, value >> 8)
		packet:setbyte(base + offset + 1, value & 0xff)
	end

	local int = function (offset, value)
		packet:setbyte(base + offset, value >> 24)
		packet:setbyte(base + offset + 1, value >> 16)
		packet:setbyte(base + offset + 2, value >> 8)
		packet:setbyte(base + offset + 3, value & 0xff)
	end

	local str = function (offset, value)
		return packet:setstring(base + offset, value)
	end

	return byte, short, int, str
end

return unpack

