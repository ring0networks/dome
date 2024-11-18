--
-- SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
-- SPDX-License-Identifier: GPL-2.0-only
--

local socket = require("socket")
local lfs = require("lfs")

local header = 'http,host=ring-0.io,location=rj'
local flow = 100 -- ~ request/second  (max: 4000)

math.randomseed(os.time())

function read_file_to_table(file_name)
    local file = io.open(file_name, "r")

    if not file then
        print("Error opening the file: " .. file_name)
        return nil
    end

    local words_table = {}
    for line in file:lines() do
        table.insert(words_table, line)
    end

    io.close(file)
    return words_table
end

-- traverse lists directory and returns lists table
function tlists(dir)
    local tlists = {}
    local function is_directory(path)
        return lfs.attributes(path, "mode") == "directory"
    end

    for file in lfs.dir(dir) do
        if file ~= "." and file ~= ".." then
            local subdir_path = dir .. "/" .. file
            if is_directory(subdir_path) then
                tlists[file] = {}
                for subfile in lfs.dir(subdir_path) do
                    if subfile ~= "." and subfile ~= ".." then
                        local tlist = read_file_to_table(subdir_path .. "/" .. subfile)
                        tlists[file][subfile:sub(0,-5)] = tlist
                    end
                end
            end
        end
    end
    return tlists
end

local lists = tlists("lists")

local FLOW_BASE = 4000

local function getline(action, reason, domain)
  local timestamp = string.sub(math.floor(socket.gettime() * 1000) .. "00" ..
  math.floor(os.clock() * 1000000), 1,19)
  return header .. ' reason="' .. reason .. '",domain="' .. domain ..
  '",action="' .. action .. '"' .. " " ..  timestamp
end

-- generates random pass/warn/block data
for action, _reason in pairs(lists) do
  for reason, domains in pairs(_reason) do
    for _, domain in ipairs(domains) do
      if math.random(1,FLOW_BASE/flow) == 1 then
        print(getline(action, reason, domain))
      end
    end
  end
end

-- generates 3 times more random pass data
for i=1,2,3 do
  local action = "pass"
  for reason, domains in pairs(lists[action]) do
    for _, domain in ipairs(domains) do
      if math.random(1,FLOW_BASE/flow) == 1 then
        print(getline(action, reason, domain))
      end
    end
  end
end
