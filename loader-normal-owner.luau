local base = "https://raw.githubusercontent.com/DarkBotGen/tifahop-loader/normal-hive-safe-v4/normal-owner-parts/"
local parts = {}
for index, expectedBytes in ipairs({2911747, 2911774}) do
    local part = game:HttpGet(base .. "part-" .. index .. ".txt")
    assert(#part == expectedBytes, "NovaHop download incomplete (part " .. index .. ")")
    parts[index] = part
end
local run, reason = loadstring(table.concat(parts), "@NovaHopPremium.Owner")
assert(run, reason)
return run()
