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

local data      = require("data") 
local blockpage = require ("dome/blockpage")

-- Example from: https://www.packetmania.net/en/2021/12/26/IPv4-IPv6-checksum

local test = { 
	data = '\x00\x60\x47\x41\x11\xc9\x00\x09\x6b\x7a\x5b\x3b\x08\x00\x45\x00' .. 
		'\x00\x1c\x74\x68\x00\x00\x80\x11\x59\x8f\xc0\xa8\x64\x01\xab\x46' .. 
		'\x9c\xe9\x0f\x3a\x04\x05\x00\x08\x7f\xc5\x00\x00\x00\x00\x00\x00' .. 
		'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x30\x20\x10'
}

function test:init()
	self.packet = data.new(#self.data)
	self.packet:setstring(0, self.data)
end

function test:assert(name, expect, result)
	if result ~= expect then
		error(string.format("(tests) %s: ERR! expected %s, got: %s", 
			name, tostring(expect), tostring(result)))
	else
		print(string.format("(tests) %s: OK", name))
	end
end

function test:checksum()
	self:init()

	self.packet:setbyte(14 + 10, 0)
	self.packet:setbyte(14 + 11, 0)

	local size = 20 -- 0x45 to 0xe9
	local header = self.packet:getstring(14, size)
	local sum = blockpage.checksum(header, size)
	local expect = 0x598f

	self:assert("tests:blockpage:checksum", sum, expect)
end

function test:edit()
	self:init()
	
	local eth1, ip1 = blockpage.ethhdr(self.packet), blockpage.iphdr(self.packet)
	blockpage.edit(self.packet)
	local eth2, ip2 = blockpage.ethhdr(self.packet), blockpage.iphdr(self.packet)

	self:assert("tests:blockpage:edit", eth1.src, eth2.dst)
	self:assert("tests:blockpage:edit", eth1.dst, eth2.src)
	self:assert("tests:blockpage:edit", ip1.src, ip2.dst)
	self:assert("tests:blockpage:edit", ip1.dst, ip2.src)
end

function test:all()
	self:checksum()
	self:edit()
end

return test
