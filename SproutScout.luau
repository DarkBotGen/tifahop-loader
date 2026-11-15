-- Standalone NovaHop Sprout scout. Execute this file directly or use loadstring.
local LOADER = "https://raw.githubusercontent.com/DarkBotGen/tifahop-loader/headless-sprout-lite-v2/SproutScout.luau"
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
    return nil, status or "request failed"
end

local brickLevels = {
    ["Sage green"] = 1,
    ["Light grey metallic"] = 2,
    ["Medium blue"] = 3,
    ["Alder"] = 5,
}
local appearance = {
    Plastic = {0.705882, 0.745098, 0.729412, 1},
    Glass = {0.658824, 0.654902, 0.662745, 2},
    Neon = {0.403922, 0.635294, 0.788235, 3},
}

local function sproutLevel(part)
    local style = appearance[part.Material.Name]
    local color = part.Color
    if style and math.abs(color.R - style[1]) < 0.06
        and math.abs(color.G - style[2]) < 0.06 and math.abs(color.B - style[3]) < 0.06 then
        return style[4]
    end
    return brickLevels[part.BrickColor.Name] or 4
end

local function nearestField(position, zones)
    local best, bestDistance
    for _, zone in ipairs(zones:GetChildren()) do
        if zone:IsA("BasePart") then
            local point = zone.CFrame:PointToObjectSpace(position)
            local dx = math.max(math.abs(point.X) - zone.Size.X / 2, 0)
            local dz = math.max(math.abs(point.Z) - zone.Size.Z / 2, 0)
            local distance = dx * dx + dz * dz
            if not bestDistance or distance < bestDistance then
                best, bestDistance = zone, distance
            end
        end
    end
    return best and best.Name
end

local function findSprout()
    local sprouts = world:FindFirstChild("Sprouts")
    local zones = world:FindFirstChild("FlowerZones")
    if not sprouts or not zones then return end
    local best, level, field
    for _, sprout in ipairs(sprouts:GetChildren()) do
        if sprout.Name == "Sprout" then
            local part = sprout:IsA("BasePart") and sprout or sprout:FindFirstChildWhichIsA("BasePart", true)
            if part then
                local rank = sproutLevel(part)
                local name = nearestField(part.Position, zones)
                if name and (not level or rank > level) then
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
            local body, failure = fetch(url, "GET")
            if not body then return nil, "server list HTTP " .. tostring(failure) end
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
    while true do
        local start = os.clock()
        local sprout, level, field
        repeat
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
                local posted, failure = fetch(RELAY .. "/nh_" .. ROOM, "POST", report)
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

        local hopping, failure = hop()
        if not hopping then warn("[Sprout Scout] Hop unavailable: " .. tostring(failure)) end
        task.wait(hopping and 18 or 8)
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
