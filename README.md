# TifaHop — walking and normal interactions

The `movement-cannon-v1` build adds a Movement tab for Walk/Tween selection, tween speed, walking speed, dynamic walking speed and Red Cannon use. Hive claiming always walks to the visible in-range Claim Hive interaction.

This does not establish that automation is permitted by the game or guarantee against account action. Live gameplay has not been tested.

## Loader

Rejoin before switching from an earlier running build. Then execute this and press Start:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/DarkBotGen/tifahop-loader/movement-cannon-v1/loader.luau"))({
    ViciousMovement = "Walk", -- or Tween; also selectable in Movement
    TweenSpeed = 50,
    UseRedCannon = true,
    DontHop = false,
    WalkSpeedEnabled = true,
    WalkSpeed = 50,
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
- Vicious combat stays on the field and uses normal MoveTo and the existing physically collected token engine. Bees perform normal attacks. No fighting platform is created, and uses your configured walking speed. Ground combat can behave differently from the former platform strategy.
- Red Cannon shortcuts are optional. The character walks to the real platform and must be close enough for the genuine `Fire the Red Cannon` prompt before E is sent. Only the game's cannon trajectory and normal glider inputs move the character through the air. Locked prompts, missed launches or landings cause walking replanning.
- Equipped tools use their normal Activate action. Automatic remote-based sprinkler and planter actions are disabled. Legacy generic game-remote interaction helpers are disabled. Honey conversion activation, if used, requires proximity to the owned hive and the game's matching honey-making prompt.
- Server hopping through TeleportService is retained, as requested. It is separate from movement within the map. `DontHop = true` disables the ordinary farming hop decisions; the separate original error/rejoin recovery still exists.

## Modes and settings

The Vichop GUI section farms Vicious Bees within the inclusive level bounds (integers 1–12). Use the same main Roblox username and room on participating accounts; username matching is case-insensitive. An empty room disables grouped roles.

The Fireflies GUI section independently farms stationary NPCBees/Firefly objects during 19:00–05:00, approaches their fields and collects nearby drops. It skips immediate revisits, searches again, and invokes the existing server hopper after 20 seconds without a usable target or a 180-second session. It searches successive servers for night rather than guaranteeing a night destination. With DontHop enabled, it stays and keeps checking. Main/alt coordination is only used by Vicious mode.

The loader caches the exact backend for rejoin recovery and saves per-account options under TifaHop/. The script requires its original Roblox/executor APIs and remote HTTP services for features such as server discovery and group coordination. Existing relay hosting has not been replaced.

## Walking speed and dodging

WalkSpeedEnabled and WalkSpeed (1–100) persist in the loader configuration. UI toggle and speed changes are saved while running and applied to the current Humanoid, including after respawn. Disabling restores its previous speed when TifaHop still owns the current override. Walking routes and combat use that same Humanoid speed.

Ground combat avoids visible nearby WarningDisk, spike and impale parts in workspace.Particles. It scores clear, in-field escape directions, considers the route through markers, and pauses combat loot movement while dodging. Unknown or unreplicated attack markers cannot be detected. Live-game attack recognition has not been verified.

## Select farming in the GUI

Select Vichop, Fireflies, Sprouts or Windy, then enable Start. Changing the selected farm stops the current run; press Start for the new farm. The existing GUI settings save the selection across reloads. Fireflies has its own section and uses normal hive claiming, walking, night-server hopping and token collection. The loader no longer sets or overrides farming mode. Older Mode entries are ignored. Farm tabs use two rows to fit the Fireflies label.

## Cannon preference

With Red Cannon enabled, eligible travel between fields commits to walking to the cannon, launching and steering toward the destination before finishing locally. It does not reselect a cheaper walking route after reaching the cannon. Pepper Patch always uses normal walking. Local positioning and hive claiming do not return to the cannon. Missing/unavailable cannon uses ordinary movement; a failed committed launch stops that travel and reports failure. The closest authored launch profile is used for destinations without an exact profile, so live landing accuracy remains unverified.

Opening Movement does not change the selected farm. Use tween movement switches the general travel method; tween cancellation handles Stop, death, respawn and toggling back to Walk. Red Cannon preference takes priority for inter-field travel when enabled.
