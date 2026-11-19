local base = "https://raw.githubusercontent.com/DarkBotGen/tifahop-loader/normal-hive-walk-v1/normal-owner-parts/"
local parts = {}
for index, expectedBytes in ipairs({2911443, 2911496}) do
    local part = game:HttpGet(base .. "part-" .. index .. ".txt")
    assert(#part == expectedBytes, "NovaHop download incomplete (part " .. index .. ")")
    parts[index] = part
end
local run, reason = loadstring(table.concat(parts), "@NovaHopPremium.Owner")
assert(run, reason)
return run()
