# TifaHop — walking and normal interactions

The `target-first-v1` build uses normal Humanoid walking and visible, in-range game interactions. It removes the recovered direct game-remote invocation helpers, flying/tween movement, noclip helper, character speed overrides, tween-to-token shortcut and Vicious fighting platform. Legacy `ViciousMovement = "Tween"` configurations are converted to Walk. UI animation tweens are unrelated to character movement.

This does not establish that automation is permitted by the game or guarantee against account action. Live gameplay has not been tested.

## Loader

Rejoin before switching from an earlier running build. Then execute this and press Start:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/DarkBotGen/tifahop-loader/target-first-v1/loader.luau"))({
    Mode = "Vicious", -- "Vicious" or "Fireflies"
    ViciousMovement = "Walk",
    UseRedCannon = true,
    DontHop = false,
    MinViciousLevel = 1,
    MaxViciousLevel = 12,
    MainAccount = "YourMainUsername",
    Group = "YourSharedRoom",
})
```

## Hive claiming

The script searches first and claims no hive on an empty server. After selecting a live Vicious Bee, sprout, Windy Bee, Mondo Chick, or stationary nighttime Firefly, it checks for confirmed hive ownership. If that target disappears or dies while approaching a hive, claiming stops. Without a hive, it selects a vacant hive and walks to its path-arrow base. Cannon shortcuts are disabled for this claim route. It sends the normal E key only when the character is within eight studs, within six studs vertically, and the visible game prompt says `Claim Hive`. Proximity is checked again immediately before input. It then waits for the ownership/spawn state to replicate. It never invokes a ClaimHive remote. Taken slots are skipped; failed movement or interaction does not allow farming to proceed without confirmed ownership.

## Movement and interaction limits

- Walking uses 3,439 route nodes and 22,048 baseline walk/jump links from the supplied Atlas reference. Normal jump waypoints are supported; there is no character-position assignment, flying physics or noclip fallback.
- Vicious combat stays on the field and uses normal MoveTo and the existing physically collected token engine. Bees perform normal attacks. No fighting platform is created, and the character's real game WalkSpeed is retained. Ground combat can behave differently from the former platform strategy.
- Red Cannon shortcuts are optional. The character walks to the real platform and must be close enough for the genuine `Fire the Red Cannon` prompt before E is sent. Only the game's cannon trajectory and normal glider inputs move the character through the air. Locked prompts, missed launches or landings cause walking replanning.
- Equipped tools use their normal Activate action. Automatic remote-based sprinkler and planter actions are disabled. Legacy generic game-remote interaction helpers are disabled. Honey conversion activation, if used, requires proximity to the owned hive and the game's matching honey-making prompt.
- Server hopping through TeleportService is retained, as requested. It is separate from movement within the map. `DontHop = true` disables the ordinary farming hop decisions; the separate original error/rejoin recovery still exists.

## Modes and settings

`Mode = "Vicious"` farms Vicious Bees within the inclusive level bounds (integers 1–12). Use the same main Roblox username and room on participating accounts; username matching is case-insensitive. An empty room disables grouped roles.

`Mode = "Fireflies"` independently farms stationary NPCBees/Firefly objects during 19:00–05:00, approaches their fields and collects nearby drops. It skips immediate revisits, searches again, and invokes the existing server hopper after 20 seconds without a usable target or a 180-second session. It searches successive servers for night rather than guaranteeing a night destination. With DontHop enabled, it stays and keeps checking. Main/alt coordination is only used by Vicious mode.

The loader caches the exact backend for rejoin recovery and saves per-account options under TifaHop/. The script requires its original Roblox/executor APIs and remote HTTP services for features such as server discovery and group coordination. Existing relay hosting has not been replaced.
