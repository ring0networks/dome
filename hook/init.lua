--
-- SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
-- SPDX-License-Identifier: GPL-2.0-only
--

local config = require("dome/config")

local hook = config.filter == "netfilter" and
	require("dome/hook.netfilter") or require("dome/hook.xdp")

hook.action_name = {}

for name, action in pairs(hook.action) do
	hook.action_name[action] = string.lower(name)
end

return hook

