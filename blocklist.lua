--
-- SPDX-FileCopyrightText: (c) 2025 Ring Zero Desenvolvimento de Software LTDA
--

local maxlines = 100000
local nlines = 1
local nfiles = 1
local name = arg[1]

local file = io.open(name .. '.lua', 'w')
file:write("local list = {\n")

for domain in io.lines('blocklist/' .. name .. "-nl.txt") do
	if nlines > maxlines then
		file:write("}\nlocal next = require('dome/" .. name .. "-" .. nfiles ..
			"')\nreturn setmetatable(list, {__index = next})\n")
		file:close()

		file = io.open(name .. '-' .. tostring(nfiles) .. '.lua', 'w')
		file:write("local list = {\n")

		nfiles = nfiles + 1
		nlines = 1
	end

	local sni = domain:match("[%w%.%-_]*")
	if #sni > 0 then
		file:write("['" .. sni .. "'] = true,\n")
		nlines = nlines + 1
	end
end

file:write("}\nreturn list\n")
file:close()

print(arg[1] .. ': ' .. nfiles)

