-- Standalone NovaHop Sprout scout. Execute this file directly or use loadstring.
local LOADER = "https://raw.githubusercontent.com/DarkBotGen/tifahop-loader/headless-sprout-lite-v10/SproutScout.luau"
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

local ranks = {rare = 2, epic = 4, legendary = 4, supreme = 4}
local excluded = {gummy = true, moon = true, basic = true, common = true, festive = true, sticker = true, debug = true}
local rarityKeys = {"Rarity", "SproutType", "Type"}

local function rarityRank(value)
    if type(value) ~= "string" then return nil end
    local name = value:lower():match("^%s*(.-)%s*$"):gsub(" sprout$", "")
    return ranks[name] or (excluded[name] and 0 or nil)
end

local function readRank(instance)
    local named = rarityRank(instance.Name)
    if named then return named end
    for _, key in ipairs(rarityKeys) do
        local ok, value = pcall(function() return instance:GetAttribute(key) end)
        local rank = ok and rarityRank(value)
        if rank then return rank end
        local childOk, childValue = pcall(function()
            local child = instance:FindFirstChild(key)
            return child and child.Value
        end)
        rank = childOk and rarityRank(childValue)
        if rank then return rank end
    end
end

local function allowedSproutRank(sprout, part)
    local rank = readRank(sprout)
    if not rank and part and part ~= sprout then rank = readRank(part) end
    if rank then return rank > 0 and rank or nil end
    if not part then return nil end
    local ok, brick = pcall(function() return part.BrickColor.Name end)
    if ok then
        if brick == "Alder" or brick == "Medium blue" or brick == "Sage green" then return nil end
        if brick == "Light grey metallic" then return 2 end
    end
    local colorOk, color = pcall(function() return part.Color end)
    if not colorOk or not color then
        if not ok then return nil end
        local brickOk, brickColor = pcall(function() return part.BrickColor.Color end)
        if not brickOk or not brickColor then return nil end
        color = brickColor
    end
    local r, g, b = color.R, color.G, color.B
    local materialOk, material = pcall(function() return part.Material.Name end)
    if materialOk and material == "Glass" and math.abs(r - 0.658824) < 0.06
        and math.abs(g - 0.654902) < 0.06 and math.abs(b - 0.662745) < 0.06 then
        return 2
    end
    local transparent, alpha = pcall(function() return part.Transparency end)
    if transparent and type(alpha) == "number" and alpha > 0.05 then return nil end
    local gold = r >= 0.75 and g >= 0.5 and b <= 0.35 and r >= g
    local teal = g >= 0.55 and b >= 0.43 and r <= 0.42 and g >= b * 0.86
    local brightGreen = materialOk and material == "Neon" and g >= 0.75 and g - r >= 0.32 and g - b >= 0.32
    if gold or teal or brightGreen then return 4 end
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

local function findSprout(handled)
    local sprouts = world:FindFirstChild("Sprouts")
    if not sprouts then return nil, nil, nil, nil end
    local best, level, bestPart
    local visible = 0
    for _, sprout in ipairs(sprouts:GetChildren()) do
        if not handled[sprout] and (sprout.Name == "Sprout" or rarityRank(sprout.Name)) then
            local part = sprout:IsA("BasePart") and sprout or sprout:FindFirstChildWhichIsA("BasePart", true)
            visible += 1
            local rank = allowedSproutRank(sprout, part)
            if rank and (not level or rank > level) then
                best, level, bestPart = sprout, rank, part
                if rank == 4 then break end
            end
        end
    end
    if best then
        local field = resolveField(best, bestPart, world:FindFirstChild("FlowerZones"))
        return best, level, field, visible
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
    if not queue then
        warn("[Sprout Scout] Re-run this script after each hop if your launcher does not auto-execute it.")
    end
    local roomUrl = RELAY .. "/nh_" .. ROOM
    local recent = {}
    for job, stamp in pairs(env.NovaHopScoutRecent or {}) do
        if type(job) == "string" and #job <= 64 and type(stamp) == "number" and os.time() - stamp < 300 then
            recent[job] = stamp
        end
    end
    env.NovaHopScoutRecent = recent
    recent[game.JobId] = os.time()
    local queued = false

    -- Carry a bounded batch across queued teleports. Refresh once it ages out.
    local candidates = {}
    local batchTime = 0
    local previous = env.NovaHopScoutBatch
    if type(previous) == "table" and type(previous.at) == "number"
        and os.time() - previous.at < 120 and type(previous.ids) == "table" then
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
        if os.time() - batchTime >= 120 then table.clear(candidates) end
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
        env.NovaHopScoutBatch = {at = batchTime, ids = candidates}
        if queue and not queued then
            local visits, ids = {}, {}
            for id, stamp in pairs(recent) do
                table.insert(visits, ("[%q]=%d"):format(id, stamp))
            end
            for _, id in ipairs(candidates) do table.insert(ids, ("%q"):format(id)) end
            local resume = ("local e=getgenv();e.NovaHopScoutRecent={%s};e.NovaHopScoutBatch={at=%d,ids={%s}};loadstring(game:HttpGet(%q))(%q)")
                :format(table.concat(visits, ","), batchTime, table.concat(ids, ","), LOADER, relayHeader)
            local ok, result = pcall(queue, resume)
            queued = ok and result ~= false
            if not queued then warn("[Sprout Scout] Automatic restart could not be queued.") end
        end
        return pcall(teleport.TeleportToPlaceInstance, teleport, game.PlaceId, job, player)
    end

    print("[Sprout Scout] Searching room " .. ROOM .. " for " .. MAIN)
    local rateDelay = 15
    local nextHop = os.clock() + math.random(0, 12)
    local handled = setmetatable({}, {__mode = "k"})
    local nextScanLog = os.clock()
    while true do
        local start = os.clock()
        local sprout, level, field, visible
        repeat
            sprout, level, field, visible = findSprout(handled)
            if not sprout then task.wait(1) end
        until sprout or os.clock() - start >= SCAN_SECONDS

        if not sprout and os.clock() >= nextScanLog then
            if visible == nil then
                print("[Sprout Scout] Sprouts folder is not visible in this server.")
            else
                print(("[Sprout Scout] Scanned this server: %d unhandled sprouts visible, none classified as Rare+."):format(visible))
            end
            nextScanLog = os.clock() + 45
        end

        if sprout and mainIsHere() then handled[sprout] = true end
        if sprout and not handled[sprout] then
            print(("[Sprout Scout] Found %s sprout in %s. Sending report."):format(level == 2 and "Rare" or "Epic+", field))
            local deadline = os.clock() + HANDOFF_SECONDS
            local report = http:JSONEncode({
                t = "spr", job = game.JobId, lvl = level, gifted = false, field = field, by = player.Name,
            })
            local announced = false
            repeat
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
            if announced or mainIsHere() then handled[sprout] = true end
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
                nextHop = os.clock() + (hopping and 18 or (8 + math.random(0, 5)))
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
