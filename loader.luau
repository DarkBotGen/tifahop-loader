-- Use the same MainAccount and Group on your main account and all alts.
local Config = ... or {
    MinViciousLevel = 1,
    MaxViciousLevel = 12,
    DontHop = false,
    MainAccount = "", -- Roblox username; matching account becomes main.
    Group = "",       -- Shared TifaHop room; empty disables grouping.
}

local source = game:HttpGet("https://raw.githubusercontent.com/DarkBotGen/tifahop-loader/3f5a2551359280a2dd7898ec4a27a11ab745d9ea/TifaHop.luau")
local run, reason = loadstring(source, "@TifaHop")
assert(run, "[TifaHop] Compilation failed: " .. tostring(reason))
-- Cache the backend for the script's existing rejoin/teleport bootstrap.
if writefile and makefolder and isfolder then
    if not isfolder("TifaHop") then makefolder("TifaHop") end
    writefile("TifaHop/source_premium.lua", source)
end
return run(Config)
