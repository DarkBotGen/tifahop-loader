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
]==]
local function replace(pattern, replacement, expected)
    local count
    source, count = source:gsub(pattern, function() return replacement end)
    assert(count == expected, "NovaHop Sprout filter could not be applied")
end
replace(marker, filter .. "\n" .. marker, 1)
replace("aY = a5%(a4%)", "aY = epicSprout(bz)", 2)
replace("bE = bq%.kind == ac", "bE = bq.kind == ac and (ac ~= 'spr' or bq.lvl == 4)", 2)
local run, reason = loadstring(source, "@NovaHopPremium.Owner")
assert(run, reason)
return run()
