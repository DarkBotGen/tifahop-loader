local base = "https://raw.githubusercontent.com/DarkBotGen/tifahop-loader/owner-chunked-v2/owner-parts/"
local parts = {}
for index, expectedBytes in ipairs({2910607, 2910639}) do
    local part = game:HttpGet(base .. "part-" .. index .. ".txt")
    assert(#part == expectedBytes, "NovaHop download incomplete (part " .. index .. ")")
    parts[index] = part
end
local source = table.concat(parts)
local marker = "local ownerDashboardSeed"
local filter = [==[
local function allowedSproutRank(sprout)
    local allowed = {rare = 2, epic = 4, legendary = 4, supreme = 4}
    for _, attribute in ipairs({"Rarity", "SproutType", "Type"}) do
        local ok, value = pcall(function() return sprout:GetAttribute(attribute) end)
        if ok and type(value) == "string" then
            local name = value:lower():match("^%s*(.-)%s*$"):gsub(" sprout$", "")
            if allowed[name] then return allowed[name] end
            if name == "gummy" or name == "moon" or name == "basic"
                or name == "common" or name == "festive" or name == "sticker" then return nil end
        end
    end

    local part = sprout:IsA("BasePart") and sprout or sprout:FindFirstChildWhichIsA("BasePart", true)
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
]==]
local function replace(pattern, replacement, expected)
    local count
    source, count = source:gsub(pattern, function() return replacement end)
    assert(count == expected, "NovaHop Sprout filter could not be applied")
end
replace(marker, filter .. "\n" .. marker, 1)
replace("aY = a5%(a4%)", "aY = allowedSproutRank(bz) ~= nil", 2)
replace("bE = bq%.kind == ac", "bE = bq.kind == ac and (ac ~= 'spr' or bq.lvl == 2 or bq.lvl == 4)", 2)
replace("a9 = cm%.farmrare == false", "a9 = false", 2)
local sproutReports = [==[
if ac == "spr" then
    dc[40]()
    local now, reports = os.time(), {}
    for _, report in pairs(co.events) do
        if report.kind == "spr" and (report.lvl == 0 or report.lvl == 2 or report.lvl == 4)
            and report.job ~= game.JobId and not report.claimed and type(report.last) == "number" then
            local age = now - report.last
            if age >= -15 and age <= (report.lvl == 0 and 45 or 240) then
                table.insert(reports, {
                    job = report.job, field = report.field or "?", gifted = false, lvl = report.lvl, age = age,
                })
            end
        end
    end
    table.sort(reports, function(left, right)
        if left.lvl ~= right.lvl then return left.lvl > right.lvl end
        return left.age < right.age
    end)
    if #reports > 0 then
        print(("[NovaHop] %d Sprout relay lead(s). Next field: %s"):format(#reports, reports[1].field))
    elseif os.clock() >= (co.nextSproutStatusLog or 0) then
        co.nextSproutStatusLog = os.clock() + 30
        print("[NovaHop] No fresh Rare+ Sprout reports or unverified leads in room " .. cm.room)
    end
    return reports
end
]==]
local roleGuard = 'if multiMainEnabled(cm) and assigned ~= multiMainName(ct.Name) then return {} end'
local roleGuardPattern = roleGuard:gsub("([^%w%s])", "%%%1")
replace(roleGuardPattern, roleGuard .. "\n" .. sproutReports, 2)
local run, reason = loadstring(source, "@NovaHopPremium.Owner")
assert(run, reason)
return run()
