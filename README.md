# TifaHop

Configurable Luau loader and recovered runtime.

The local license screen and its module have been removed. Startup now enters the automation directly, retaining error reporting and duplicate-start protection. No license server is called or impersonated by the replacement startup. The update also closes the old prompt if a preceding build already displayed it.

Copy `loader.luau` into your executor and edit only these settings:

```lua
local Config = {
    Mode = "Vicious", -- "Vicious" or "Fireflies"
    MinViciousLevel = 1,
    MaxViciousLevel = 12,
    DontHop = false,
    ViciousMovement = "Walk", -- "Walk" or "Tween"
    UseRedCannon = true,
    MainAccount = "YourMainUsername",
    Group = "YourSharedRoom",
}
```

Or launch the hosted loader directly with those same controls:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/DarkBotGen/tifahop-loader/grind-v1/loader.luau"))({
    Mode = "Fireflies", -- "Fireflies" or "Vicious"
    MinViciousLevel = 1,
    MaxViciousLevel = 12,
    DontHop = false,
    ViciousMovement = "Walk", -- "Walk" or "Tween"
    UseRedCannon = true,
    MainAccount = "YourMainUsername",
    Group = "YourSharedRoom",
})
```

- Vicious levels are inclusive integers from 1 to 12; minimum cannot exceed maximum.
- `Mode = "Fireflies"` enables night-time firefly farming and hopping; `"Vicious"` preserves Vicious farming. Press the existing Start control after loading. The selected mode is saved for rejoin recovery.
- `UseRedCannon = true` enables costed Red Cannon shortcuts in walking routes. The account must be able to activate the genuine cannon prompt; unavailable or missed launches fall back to walking routes. Other cannons and portals are not enabled.
- `DontHop = true` sets the original script's no-hop setting. Its separate error/rejoin recovery still exists.
- `ViciousMovement` selects `"Walk"` (map routes) or `"Tween"` (original flying movement). It also sets the initial general movement selector, so field travel uses the new walking router in Walk mode. Default is `"Walk"`. The selection is saved for rejoin recovery. Change the loader value and rejoin to switch an already running session.
- `MainAccount` is the Roblox **username**, not display name. Matching is case-insensitive. The matching account is main; other accounts using the same group are alts.
- Use the same `MainAccount` and `Group` on every participating account. A nonempty group requires a main username.
- Empty `Group` disables grouped roles. Group is this script's shared coordination room, not a Roblox group ID. Room names are not authenticated access controls.
- Main/alt group coordination applies to Vicious mode. Fireflies mode farms independently on each account; it preserves but does not use the group settings.

The loader downloads `TifaHop.luau` and calls it with the configuration table. It caches the backend as `TifaHop/source_premium.lua` for the original rejoin bootstrap. Each account's loader configuration is saved under `TifaHop/loader_<UserId>.json`; the cached backend can reload it when a server transition starts a new session.

The requested controls override the old saved settings at startup. Other features retain the recovered defaults and original UI controls. This does not remove UI tabs or features from the underlying program.

## Claim hive before Vicious Bees

The `hive-v1` build gates both Vicious search and combat on confirmed hive ownership. It invokes the session's existing hive-claim implementation, waits for the player's Honeycomb reference or matching hive/platform owner to replicate, and waits for a nonnegative spawn position. A successful return from the claim routine alone is not accepted. Existing ownership avoids unnecessary reclaims. Claims retry twice; stopped workers exit promptly, and failure pauses Vicious activity with a status message.

The current `grind-v1` release includes this hive-first behavior and applies it to Fireflies mode too.

## Fireflies grind mode

Fireflies mode follows the supplied Atlas behavior: find stationary Firefly objects in NPCBees using BodyVelocity, operate during the 19:00–05:00 night window, travel to the containing field, approach on the ground, suppress immediate revisits for two seconds, and use the existing token collection engine for nearby drops. Failed targets are temporarily skipped. The original Start/Stop and generation-token checks control the worker.

When no usable fireflies are found for 20 seconds, or after a 180-second server session, it invokes the existing server hopper and restores the selected configuration in the new server. It searches successive servers for night/fireflies; it cannot guarantee that an arbitrary destination server is at night. With `DontHop = true`, it remains in the current server and keeps checking. It does not activate the reference's unrelated memory-match, conversion or item-use features.

## Red Cannon shortcuts

The map planner can use the reference's four Red Cannon entry nodes and 21 landing profiles. Cannon edges are priced by expected flight time, so they are selected only when the calculated route is cheaper. Execution approaches the real platform, checks for `Fire the Red Cannon`, activates it using the existing input API, follows the reference's jump/glider timing and waits for landing. A locked prompt or missed landing disables cannon shortcuts for the session, allowing replanning on foot. Cancel/Stop interrupts the flight sequence.

## Walking to Vicious Bees

The `routes-v1` build uses an Atlas-style map graph extracted from the user-provided reference: 3,439 coordinates and 22,048 walk/jump links. A* selects a route through these known map connections. The same router replaces the recovered general walking callback, which previously aborted immediately. Special cannon, portal, reset and glider links are excluded; this router does not activate those mechanics.

Vicious navigation first locates the containing field, routes to it, then walks on the ground below the bee. Arrival uses horizontal distance with a vertical safety bound, so a floating Vicious root is not treated as a ground-level walking destination. Jump links and elevation changes trigger normal humanoid jumps. Blocked links are excluded during bounded replanning. Stop/cancellation, character death and disappearing targets interrupt navigation. `ViciousMovement = "Tween"` restores the original approach callback.

Unreachable targets produce a status message and abort the approach; navigation does not fall back to flying. Total navigation time and failed route attempts are bounded. Combat positioning, including the existing fighting platform, stays as before after arrival. General field travel now uses the same map router when its movement selector is Walk. Other explicitly scripted combat/interaction movements are retained.

If an earlier version is already running, rejoin before using this release. The duplicate-start guard prevents a second running copy from replacing it in the same server.

## Environment and validation

Requires the original Roblox/executor APIs, filesystem/HTTP capabilities and non-license remote services. Branding, local paths and internal session prefixes use TifaHop. The existing third-party relay endpoint is preserved; it has not been moved or replaced by this repository. Removing the local license module does not change access rules on external services.

The full runtime and loader compile with the official Luau compiler. The preceding runtime reconstruction passed 23 isolated differential tests against its original interpreter. Loader configuration, account roles and persistence are tested with mocked services. Live Roblox automation and the external relay have not been tested.

`build_map.json` preserves original function IDs and instruction block addresses for inspection. Source uses a program counter in place of unsupported goto syntax.
