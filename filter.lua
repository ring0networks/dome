--
-- SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
-- SPDX-License-Identifier: GPL-2.0-only
--

local lunatik = require("lunatik")
local thread  = require("thread")
local rcu     = require("rcu") -- used for lunatik.runtimes()

local runtimes = lunatik.runtimes()

local filter = {}

function filter.__gc(self)
	self.runtime:stop()
end

function filter.new(name, queue)
	local name = 'dome/' .. name

	if runtimes[name] then
		error(string.format("%s is already running", name))
	end

	local runtime = lunatik.runtime(name, false)
	runtimes[name] = runtime 

	-- dispatch queue to filter
	thread.run(runtime, name, queue)

	return setmetatable({runtime = runtime}, filter)
end

return filter

