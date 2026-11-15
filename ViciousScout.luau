-- Standalone NovaHop Vicious Bee scout. Execute this file directly or use loadstring.
local BUILD = "vicious-scout-2"
local LOADER = "https://raw.githubusercontent.com/DarkBotGen/tifahop-loader/main/ViciousScout.luau"
local ROOM = "pork"
local MAIN = "warrior_8dragon"
local RELAY = "https://novahop-relay-ws.lmgmeee.workers.dev"
local SCAN_SECONDS = 3
local REPLICATION_WAIT = 8
local HANDOFF_SECONDS = 45

local players = game:GetService("Players")
local http = game:GetService("HttpService")
local teleport = game:GetService("TeleportService")
local world = game:GetService("Workspace")
local env = getgenv()
local suppliedKey = ...
local relayHeader = type(suppliedKey) == "string" and suppliedKey:match("^%s*(.-)%s*$") or ""
if relayHeader == "" and type(readfile) == "function" then
    local ok, saved = pcall(readfile, "NovaHopSproutRelayKey.txt")
    if ok and type(saved) == "string" then relayHeader = saved:match("^%s*(.-)%s*$") end
end
assert(relayHeader ~= "", "[Vicious Scout] Pass your relay credential to the loader as a string.")
local requestHttp = request or http_request or (syn and syn.request)
assert(type(requestHttp) == "function", "[Vicious Scout] HTTP request is unavailable.")
assert(game.PlaceId == 1537690962, "[Vicious Scout] Run this in Bee Swarm Simulator.")
repeat task.wait(0.2) until players.LocalPlayer and game.JobId ~= ""
local player = players.LocalPlayer
if player.Name:lower() == MAIN then
    warn("[Vicious Scout] Use the regular NovaHop loader on the Vicious main.")
    return
end

local function fetch(url, method, body)
    local headers
    if method == "POST" then
        headers = {["Content-Type"] = "text/plain", ["x-nh-key"] = relayHeader}
    end
    local ok, response = pcall(requestHttp, {
        Url = url,
        Method = method,
        Headers = headers,
        Body = body,
        Timeout = 10,
    })
    local status = ok and type(response) == "table" and tonumber(response.StatusCode)
    if status and status >= 200 and status < 300 then
        return response.Body or ""
    end
    local retryAfter
    if status == 429 and type(response.Headers) == "table" then
        for name, value in pairs(response.Headers) do
            if type(name) == "string" and name:lower() == "retry-after" then
                retryAfter = tonumber(value)
                break
            end
        end
    end
    return nil, status or "request failed", retryAfter
end

local function nearestField(position, zones)
    local best, bestDistance
    for _, zone in ipairs(zones:GetChildren()) do
        local ok, distance = pcall(function()
            if not zone:IsA("BasePart") then return end
            local point = zone.CFrame:PointToObjectSpace(position)
            local dx = math.max(math.abs(point.X) - zone.Size.X / 2, 0)
            local dz = math.max(math.abs(point.Z) - zone.Size.Z / 2, 0)
            return dx * dx + dz * dz
        end)
        if not ok or distance == nil then
            ok, distance = pcall(function()
                local delta = position - zone.Position
                return delta.X * delta.X + delta.Z * delta.Z
            end)
            if ok then distance += 10000 end
        end
        if ok and distance and (not bestDistance or distance < bestDistance) then
            best, bestDistance = zone, distance
        end
    end
    return best and best.Name
end

local function resolveField(sprout, part, zones)
    if not zones then return "?" end
    for _, name in ipairs({"Field", "FieldName", "Zone"}) do
        local ok, value = pcall(function() return sprout:GetAttribute(name) end)
        if ok and type(value) == "string" and zones:FindFirstChild(value) then return value end
    end
    local readers = {
        function() return part.Position end,
        function() return part.CFrame.Position end,
        function() return sprout:GetPivot().Position end,
    }
    for _, read in ipairs(readers) do
        local ok, position = pcall(read)
        if ok and position then
            local field = nearestField(position, zones)
            if field then return field end
        end
    end
    return "?"
end

local function beeLevel(bee)
    local readers = {
        function() local value = bee:FindFirstChild("Level"); return value and value.Value end,
        function() return bee:GetAttribute("Level") end,
        function() return bee.Name:match("%d+") end,
    }
    for _, read in ipairs(readers) do
        local ok, value = pcall(read)
        local level = ok and tonumber(value)
        if level and level % 1 == 0 and level >= 1 and level <= 12 then return level end
    end
end

local function findVicious(handled)
    local monsters = world:FindFirstChild("Monsters")
    if not monsters then return end
    local visible = 0
    for _, bee in ipairs(monsters:GetChildren()) do
        if not handled[bee] and bee.Name:find("Vicious Bee", 1, true) then
            visible += 1
            local level = beeLevel(bee)
            if level then
                local hasRoot, root = pcall(function() return bee:FindFirstChild("HumanoidRootPart") end)
                local field = resolveField(bee, hasRoot and root or nil, world:FindFirstChild("FlowerZones"))
                return bee, level, field, visible
            end
        end
    end
    return nil, nil, nil, visible
end

local function mainIsHere()
    for _, account in ipairs(players:GetPlayers()) do
        if account.Name:lower() == MAIN then return true end
    end
    return false
end

local function scout()
    local queue = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
    local roomUrl = RELAY .. "/nh_" .. ROOM
    local cachePath = "NovaHopViciousScout_" .. tostring(player.UserId) .. "_servers.json"
    local saved
    if type(readfile) == "function" then
        local ok, state = pcall(function() return http:JSONDecode(readfile(cachePath)) end)
        if ok and type(state) == "table" then saved = state end
    end
    local visited = env.NovaHopViciousScoutRecent or (saved and saved.recent)
    local recent = {}
    for job, stamp in pairs(type(visited) == "table" and visited or {}) do
        if type(job) == "string" and #job <= 64 and type(stamp) == "number" and os.time() - stamp < 300 then
            recent[job] = stamp
        end
    end
    env.NovaHopViciousScoutRecent = recent
    recent[game.JobId] = os.time()
    local queued = false

    -- Carry a bounded batch across queued teleports. Refresh once it ages out.
    local candidates = {}
    local batchTime = 0
    local previous = env.NovaHopViciousScoutBatch or (saved and saved.batch)
    local function saveServerState()
        if type(writefile) == "function" then
            pcall(function()
                writefile(cachePath, http:JSONEncode({recent = recent, batch = {at = batchTime, ids = candidates}}))
            end)
        end
    end
    if type(previous) == "table" and type(previous.at) == "number"
        and os.time() - previous.at < 180 and type(previous.ids) == "table" then
        batchTime = previous.at
        for _, id in ipairs(previous.ids) do
            if type(id) == "string" and #id <= 64 and not recent[id] then
                table.insert(candidates, id)
            end
            if #candidates >= 16 then break end
        end
    end
    local cursor

    local function hop()
        if os.time() - batchTime >= 180 then table.clear(candidates) end
        if #candidates == 0 then
            local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100&excludeFullGames=true"):format(game.PlaceId)
            if cursor then url ..= "&cursor=" .. http:UrlEncode(cursor) end
            local body, failure, retryAfter = fetch(url, "GET")
            if not body then return nil, "server list HTTP " .. tostring(failure), failure == 429, retryAfter end
            local ok, page = pcall(http.JSONDecode, http, body)
            if not ok or type(page) ~= "table" or type(page.data) ~= "table" then
                cursor = nil
                return nil, "invalid server list"
            end
            cursor = type(page.nextPageCursor) == "string" and page.nextPageCursor ~= "" and page.nextPageCursor or nil
            for _, server in ipairs(page.data) do
                if type(server.id) == "string" and #server.id <= 64 and not recent[server.id]
                    and type(server.playing) == "number" and type(server.maxPlayers) == "number"
                    and server.maxPlayers - server.playing >= 2 then
                    table.insert(candidates, server.id)
                end
            end
            while #candidates > 16 do table.remove(candidates, math.random(#candidates)) end
            batchTime = os.time()
        end
        if #candidates == 0 then return nil, "no eligible server on this page" end

        local job = table.remove(candidates, math.random(#candidates))
        recent[job] = os.time()
        env.NovaHopViciousScoutBatch = {at = batchTime, ids = candidates}
        saveServerState()
        if queue and not queued then
            local visits, ids = {}, {}
            for id, stamp in pairs(recent) do
                table.insert(visits, ("[%q]=%d"):format(id, stamp))
            end
            for _, id in ipairs(candidates) do table.insert(ids, ("%q"):format(id)) end
            local resume = ("local e=getgenv();e.NovaHopViciousScoutRecent={%s};e.NovaHopViciousScoutBatch={at=%d,ids={%s}};loadstring(game:HttpGet(%q))(%q)")
                :format(table.concat(visits, ","), batchTime, table.concat(ids, ","), LOADER, relayHeader)
            local ok, result = pcall(queue, resume)
            queued = ok and result ~= false
            if not queued then warn("[Vicious Scout] Automatic restart could not be queued.") end
        end
        return pcall(teleport.TeleportToPlaceInstance, teleport, game.PlaceId, job, player)
    end

    print("[Vicious Scout] " .. BUILD .. " searching room " .. ROOM .. " for " .. MAIN)
    local rateDelay = 15
    local nextHop = os.clock() + math.random(0, 5)
    local handled = setmetatable({}, {__mode = "k"})
    local nextScanLog = os.clock()
    while true do
        local start = os.clock()
        local bee, level, field, visible
        local readyAt
        repeat
            bee, level, field, visible = findVicious(handled)
            if visible ~= nil then readyAt = readyAt or os.clock() end
            if not bee then task.wait(0.25) end
        until bee or (readyAt and os.clock() - readyAt >= SCAN_SECONDS)
            or os.clock() - start >= REPLICATION_WAIT

        if not bee and os.clock() >= nextScanLog then
            if visible == nil then
                print("[Vicious Scout] Monsters folder is not visible in this server.")
            elseif visible == 0 then
                print("[Vicious Scout] Scanned this server: no Vicious Bee.")
            else
                print(("[Vicious Scout] Scanned this server: %d Vicious Bees with unreadable levels."):format(visible))
            end
            nextScanLog = os.clock() + 45
        end

        if bee and mainIsHere() then handled[bee] = true end
        if bee and not handled[bee] then
            print(("[Vicious Scout] Found level %d Vicious Bee in %s. Sending report."):format(level, field))
            local deadline = os.clock() + HANDOFF_SECONDS
            local report = http:JSONEncode({
                t = "vic", job = game.JobId, lvl = level, gifted = bee.Name:find("Gifted", 1, true) ~= nil,
                field = field, by = player.Name,
            })
            local announced = false
            repeat
                local posted, failure = fetch(roomUrl, "POST", report)
                if posted and not announced then
                    print("[Vicious Scout] Reported " .. field .. ". Waiting for " .. MAIN)
                    announced = true
                elseif not posted then
                    warn("[Vicious Scout] Relay POST failed: " .. tostring(failure))
                end
                local retry = os.clock() + (posted and 12 or 5)
                repeat task.wait(0.5)
                until not bee.Parent or mainIsHere() or os.clock() >= math.min(retry, deadline)
            until not bee.Parent or mainIsHere() or os.clock() >= deadline
            if announced or mainIsHere() then handled[bee] = true end
        end

        if os.clock() >= nextHop then
            local hopping, failure, limited, retryAfter = hop()
            if limited then
                local delay = math.max(rateDelay, retryAfter or 0) + math.random(3, 12)
                warn(("[Vicious Scout] Roblox rate limited the server list. Retrying in %.0fs."):format(delay))
                nextHop = os.clock() + delay
                rateDelay = math.min(rateDelay * 2, 180)
            else
                rateDelay = 15
                if not hopping then warn("[Vicious Scout] Hop unavailable: " .. tostring(failure)) end
                nextHop = os.clock() + (hopping and 18 or (8 + math.random(0, 5)))
            end
        end
        task.wait(1)
        for id, stamp in pairs(recent) do
            if id ~= game.JobId and os.time() - stamp >= 300 then recent[id] = nil end
        end
    end
end

if env.NovaHopViciousScoutJob == game.JobId then return end
env.NovaHopViciousScoutJob = game.JobId
local ok, reason = pcall(scout)
env.NovaHopViciousScoutJob = nil
if not ok then error(reason, 0) end
