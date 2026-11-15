-- Standalone NovaHop Sprout scout. Execute this file directly or use loadstring.
local LOADER = "https://raw.githubusercontent.com/DarkBotGen/tifahop-loader/headless-sprout-lite-v6/SproutScout.luau"
local ROOM = "pork"
local MAIN = "warrior_8dragon"
local RELAY = "https://novahop-relay-ws.lmgmeee.workers.dev"
local SCAN_SECONDS = 8
local HANDOFF_SECONDS = 75

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
assert(relayHeader ~= "", "[Sprout Scout] Pass your relay credential to the loader as a string.")
local requestHttp = request or http_request or (syn and syn.request)
assert(type(requestHttp) == "function", "[Sprout Scout] HTTP request is unavailable.")
assert(game.PlaceId == 1537690962, "[Sprout Scout] Run this in Bee Swarm Simulator.")
repeat task.wait(0.5) until players.LocalPlayer and game.JobId ~= ""
local player = players.LocalPlayer
if player.Name:lower() == MAIN then
    warn("[Sprout Scout] Use the regular NovaHop loader on the Sprout main.")
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

local function epicSprout(sprout)
    local allowed = {epic = true, legendary = true, supreme = true}
    for _, attribute in ipairs({"Rarity", "SproutType", "Type"}) do
        local ok, value = pcall(function() return sprout:GetAttribute(attribute) end)
        if ok and type(value) == "string" then
            local name = value:lower():match("^%s*(.-)%s*$"):gsub(" sprout$", "")
            if allowed[name] then return true end
            if name == "gummy" or name == "rare" or name == "moon" or name == "basic"
                or name == "common" or name == "festive" or name == "sticker" then return false end
        end
    end

    local part = sprout:IsA("BasePart") and sprout or sprout:FindFirstChildWhichIsA("BasePart", true)
    if not part then return false end
    local ok, brick = pcall(function() return part.BrickColor.Name end)
    if ok and brick == "Alder" then return false end
    local transparent, alpha = pcall(function() return part.Transparency end)
    if transparent and type(alpha) == "number" and alpha > 0.05 then return false end
    local colorOk, color = pcall(function() return part.Color end)
    if not colorOk or not color then
        if not ok then return false end
        local brickOk, brickColor = pcall(function() return part.BrickColor.Color end)
        if not brickOk or not brickColor then return false end
        color = brickColor
    end
    local r, g, b = color.R, color.G, color.B
    local materialOk, material = pcall(function() return part.Material.Name end)
    local gold = r >= 0.75 and g >= 0.5 and b <= 0.35 and r >= g
    local teal = g >= 0.55 and b >= 0.43 and r <= 0.42 and g >= b * 0.86
    local brightGreen = materialOk and material == "Neon" and g >= 0.75 and g - r >= 0.32 and g - b >= 0.32
    return gold or teal or brightGreen
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

local function findSprout()
    local sprouts = world:FindFirstChild("Sprouts")
    local zones = world:FindFirstChild("FlowerZones")
    if not sprouts then return end
    local best, level, field
    for _, sprout in ipairs(sprouts:GetChildren()) do
        if sprout.Name == "Sprout" then
            local part = sprout:IsA("BasePart") and sprout or sprout:FindFirstChildWhichIsA("BasePart", true)
            if part and epicSprout(sprout) then
                local rank = 4
                local name = resolveField(sprout, part, zones)
                if not level or rank > level then
                    best, level, field = sprout, rank, name
                end
            end
        end
    end
    return best, level, field
end

local function mainIsHere()
    for _, account in ipairs(players:GetPlayers()) do
        if account.Name:lower() == MAIN then return true end
    end
    return false
end

local function scout()
    local queue = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
    if not queue then
        warn("[Sprout Scout] Re-run this script after each hop if your launcher does not auto-execute it.")
    end
    local roomUrl = RELAY .. "/nh_" .. ROOM
    local presence = http:JSONEncode({
        t = "here",
        nonce = ("%d-%d"):format(os.time(), math.random(1, 999999999)),
        name = player.Name,
        role = "alt",
        mode = "sprouts",
        job = game.JobId,
    })
    local nextPresence = 0
    local presenceAnnounced = false
    local function publishPresence()
        if os.clock() < nextPresence then return end
        local sent, failure, retryAfter = fetch(roomUrl, "POST", presence)
        nextPresence = os.clock() + math.max(30, retryAfter or 0) + math.random(0, 5)
        if not sent then
            warn("[Sprout Scout] Room presence failed: " .. tostring(failure))
        elseif not presenceAnnounced then
            print("[Sprout Scout] Announced online in room " .. ROOM)
            presenceAnnounced = true
        end
    end

    local recent = {}
    for job, stamp in pairs(env.NovaHopScoutRecent or {}) do
        if type(job) == "string" and #job <= 64 and type(stamp) == "number" and os.time() - stamp < 300 then
            recent[job] = stamp
        end
    end
    env.NovaHopScoutRecent = recent
    recent[game.JobId] = os.time()
    local queued = false

    local function hop()
        local cursor
        for _ = 1, 3 do
            local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100&excludeFullGames=true"):format(game.PlaceId)
            if cursor then url ..= "&cursor=" .. http:UrlEncode(cursor) end
            local body, failure, retryAfter = fetch(url, "GET")
            if not body then return nil, "server list HTTP " .. tostring(failure), failure == 429, retryAfter end
            local ok, page = pcall(http.JSONDecode, http, body)
            if not ok or type(page) ~= "table" or type(page.data) ~= "table" then
                return nil, "invalid server list"
            end
            local candidates = {}
            for _, server in ipairs(page.data) do
                if type(server.id) == "string" and #server.id <= 64 and not recent[server.id]
                    and type(server.playing) == "number" and type(server.maxPlayers) == "number"
                    and server.maxPlayers - server.playing >= 2 then
                    table.insert(candidates, server.id)
                end
            end
            if #candidates > 0 then
                local job = candidates[math.random(#candidates)]
                recent[job] = os.time()
                if queue and not queued then
                    local entries = {}
                    for id, stamp in pairs(recent) do
                        table.insert(entries, ("[%q]=%d"):format(id, stamp))
                    end
                    queued = pcall(queue, "getgenv().NovaHopScoutRecent={" .. table.concat(entries, ",")
                        .. "}; loadstring(game:HttpGet(" .. string.format("%q", LOADER) .. "))(" .. string.format("%q", relayHeader) .. ")")
                    if not queued then warn("[Sprout Scout] Automatic restart could not be queued.") end
                end
                return pcall(teleport.TeleportToPlaceInstance, teleport, game.PlaceId, job, player)
            end
            cursor = page.nextPageCursor
            if type(cursor) ~= "string" or cursor == "" then break end
        end
        return nil, "no eligible server in the pages checked"
    end

    print("[Sprout Scout] Searching room " .. ROOM .. " for " .. MAIN)
    local rateDelay = 15
    local nextHop = os.clock() + math.random(0, 8)
    while true do
        local start = os.clock()
        local sprout, level, field
        repeat
            publishPresence()
            sprout, level, field = findSprout()
            if not sprout then task.wait(0.5) end
        until sprout or os.clock() - start >= SCAN_SECONDS

        if sprout and not mainIsHere() then
            local deadline = os.clock() + HANDOFF_SECONDS
            local report = http:JSONEncode({
                t = "spr", job = game.JobId, lvl = level, gifted = false, field = field, by = player.Name,
            })
            local announced = false
            repeat
                publishPresence()
                local posted, failure = fetch(roomUrl, "POST", report)
                if posted and not announced then
                    print("[Sprout Scout] Reported " .. field .. ". Waiting for " .. MAIN)
                    announced = true
                elseif not posted then
                    warn("[Sprout Scout] Relay POST failed: " .. tostring(failure))
                end
                local retry = os.clock() + (posted and 12 or 5)
                repeat task.wait(0.5)
                until not sprout.Parent or mainIsHere() or os.clock() >= math.min(retry, deadline)
            until not sprout.Parent or mainIsHere() or os.clock() >= deadline
        end

        if os.clock() >= nextHop then
            local hopping, failure, limited, retryAfter = hop()
            if limited then
                local delay = math.max(rateDelay, retryAfter or 0) + math.random(3, 12)
                warn(("[Sprout Scout] Roblox rate limited the server list. Retrying in %.0fs."):format(delay))
                nextHop = os.clock() + delay
                rateDelay = math.min(rateDelay * 2, 180)
            else
                rateDelay = 15
                if not hopping then warn("[Sprout Scout] Hop unavailable: " .. tostring(failure)) end
                nextHop = os.clock() + (hopping and 18 or 8)
            end
        end
        task.wait(1)
        for id, stamp in pairs(recent) do
            if id ~= game.JobId and os.time() - stamp >= 300 then recent[id] = nil end
        end
    end
end

if env.NovaHopSproutScoutJob == game.JobId then return end
env.NovaHopSproutScoutJob = game.JobId
local ok, reason = pcall(scout)
env.NovaHopSproutScoutJob = nil
if not ok then error(reason, 0) end
