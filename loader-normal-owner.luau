local base = "https://raw.githubusercontent.com/DarkBotGen/tifahop-loader/normal-hive-tween-v2/normal-owner-parts/"
local parts = {}
for index, expectedBytes in ipairs({2911470, 2911514}) do
    local part = game:HttpGet(base .. "part-" .. index .. ".txt")
    assert(#part == expectedBytes, "NovaHop download incomplete (part " .. index .. ")")
    parts[index] = part
end
local run, reason = loadstring(table.concat(parts), "@NovaHopPremium.Owner")
assert(run, reason)
return run()
