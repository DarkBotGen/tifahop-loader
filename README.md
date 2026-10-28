# TifaHop: three separate scripts

Rejoin before switching scripts. Run one at a time.

## Standalone Fireflies

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/DarkBotGen/tifahop-loader/fireflies-v1/loader-fireflies.luau"))()
```

Press Start Fireflies. The Movement button switches Walk/Tween and saves the choice. Tween speed defaults to 8, capped at 12. Autodig automatically equips and activates the player's normal tool. To set initial options explicitly, call the backend directly:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/DarkBotGen/tifahop-loader/fireflies-v1/TifaHop-Fireflies.luau"))({
    Movement = "Walk", -- or Tween
    TweenSpeed = 8,
    WalkSpeedEnabled = true,
    WalkSpeed = 50,
    UseRedCannon = true,
    DontHop = false,
    AutoStart = false,
})
```

The standalone backend is about 31 KB and contains no other farm workers, recovered VM or full walking graph. It uses native pathfinding for walking, TweenService for optional tween travel, and a small set of authored Red Cannon profiles. Hive claiming always walks and checks the normal in-range Claim Hive prompt. Pepper Patch walks normally.

The supplied Atlas source is used as a reference: select nearest stationary NPCBees/Firefly objects, use a two-second revisit delay, and track Sparkles/LeafBurst under workspace.Flowers. This script batches touches of stationary fireflies in the current field before harvesting sparkling flowers and nearby Collectibles. Autodig continues during farming. Sparkle markers are tracked through descendant events rather than repeatedly scanning the entire flower map.

It stays in the same server for the entire night (ClockTime 19:00 through 05:00), including periods without stationary fireflies. At daytime it hops to search for a night server, unless DontHop is on. There is no timed hop during the night. Successful queued execution resumes this standalone script and its selected movement after teleport; executors must support queue_on_teleport or its equivalents for automatic resume. Visited-server history is carried between hops. Day/night status is checked after joining, not known in advance.

Options save to TifaHop/fireflies_<UserId>.json. Start/Stop and movement selection are independent of all other TifaHop scripts.

## Walking build: other farms

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/DarkBotGen/tifahop-loader/fireflies-v1/loader-walk.luau"))()
```

## Tween build: other farms

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/DarkBotGen/tifahop-loader/fireflies-v1/loader-tween.luau"))()
```

Fireflies has been removed from both builds: no Fireflies tab, worker, hop dispatch or standalone helper engine is included. Other farm choices persist in TifaHop/farm_<UserId>.txt. Walking retains authored A* routes; Tween excludes the full route graph. Each loader fetches only its selected backend.

All three scripts sort available hives by distance and try the nearest first, rechecking ownership before interaction. If the nearest is unreachable or becomes occupied, the next nearest is attempted. No hive is claimed on empty/day servers by Fireflies.

Compilation and mocked tests pass. Live-game traversal, sparkle harvesting, cannon landing and executor teleport resume remain unverified.
