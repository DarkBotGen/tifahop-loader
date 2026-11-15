local base = "https://raw.githubusercontent.com/DarkBotGen/tifahop-loader/headless-sprout-v1/headless-sprout-parts/"
local parts = {}
for index, expectedBytes in ipairs({2910871, 2910927}) do
    local part = game:HttpGet(base .. "part-" .. index .. ".txt")
    assert(#part == expectedBytes, "NovaHop download incomplete (part " .. index .. ")")
    parts[index] = part
end
local run, reason = loadstring(table.concat(parts), "@NovaHopPremium.Owner")
assert(run, reason)
return run()
