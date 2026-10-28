# TifaHop: separate Walking and Tween scripts

Choose one build and rejoin before switching. Both retain the GUI farm sections, account/group settings and keyless startup. Movement is fixed by the script you load; there is no runtime Walk/Tween toggle.

## Walking build

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/DarkBotGen/tifahop-loader/split-v2/loader-walk.luau"))({
    WalkSpeedEnabled = true,
    WalkSpeed = 50,
    UseRedCannon = true,
    DontHop = false,
    MainAccount = "YourMainUsername",
    Group = "YourSharedRoom",
})
```

The Walking build retains the authored A* map routes and Red Cannon profiles, and excludes the Tween engine. Its compact backend is 1,725,190 bytes.

## Tween build

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/DarkBotGen/tifahop-loader/split-v2/loader-tween.luau"))({
    TweenSpeed = 8,
    UseRedCannon = true,
    DontHop = false,
    MainAccount = "YourMainUsername",
    Group = "YourSharedRoom",
})
```

The Tween build excludes the full authored walking graph and A* planner. It retains only 21 cannon destination coordinates/profiles and uses Roblox PathfindingService for physically walking to hives/cannon and Pepper Patch. Its compact backend is 1,342,095 bytes. Tween speed defaults to 8 and is capped at 12.

Both loaders fetch only their selected backend. Generated indentation, standalone comments and unreachable function definitions are removed. All farm/UI features are retained; these are smaller builds, not claims of measured live CPU or memory improvements.

## Fireflies

Select Fireflies in the GUI, then Start. This runs independently of the Vicious Bee worker and group feed. Day servers hop immediately. Night servers get a four-second check for usable stationary fireflies before hopping. Found targets trigger hive claiming and farming. Empty/day servers do not claim hives. If a teleport fails without leaving the server, the worker retries instead of returning permanently. DontHop explicitly disables these hops.

The server hopper searches successive servers; it cannot know a server's day/night state before joining. No night destination is guaranteed.

## Movement and interaction

Hive claiming always walks to a vacant hive and requires the visible Claim Hive prompt before pressing E. Inter-field travel prefers a committed Red Cannon launch when enabled; Pepper Patch walks normally, and short local travel avoids cannon trips. Launch profiles steer toward the requested destination. Combat stays on the ground and avoids visible warning disks/spikes.

Compilation and mocked regression tests pass. Live-game traversal, glide landing accuracy and attack recognition remain unverified. The original remote HTTP/relay services remain dependencies. The combined TifaHop.luau is retained for build maintenance; the two loaders do not download it.

## Persistent farm selection

Explicit GUI farm choices save immediately to TifaHop/farm_<UserId>.txt and restore across script reloads and server hops, even when loader defaults are supplied. Startup recognizes Fireflies as valid. The chosen farm takes precedence over the former automatic Mondo override, and opening Main/Movement does not select another farm. Switching farm sections stops the current farm before saving the new choice; Start runs that selected farm.
