# TifaHop: three separate scripts

Rejoin before switching scripts. Run one at a time.

## Standalone Fireflies

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/DarkBotGen/tifahop-loader/fireflies-v4/loader-fireflies.luau"))()
```

Press Start Fireflies. The Movement button switches Walk/Tween and saves the choice. Tween speed defaults to 8, capped at 12. Autodig automatically equips and activates the player's normal tool. To set initial options explicitly, call the backend directly:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/DarkBotGen/tifahop-loader/fireflies-v4/TifaHop-Fireflies.luau"))({
    Movement = "Walk", -- or Tween
    TweenSpeed = 8,
    WalkSpeedEnabled = true,
    WalkSpeed = 50,
    UseRedCannon = true,
    DontHop = false,
    AutoStart = false,
})
```

The standalone backend is about 55 KB and contains no other farm workers or recovered VM. Longer walks load a separately cached Atlas route graph when needed. It uses native pathfinding for walking, TweenService for optional tween travel, and a small set of authored Red Cannon profiles. Hive claiming always walks and checks the normal in-range Claim Hive prompt. Pepper Patch walks normally.

The supplied Atlas source is used as a reference: select nearest stationary NPCBees/Firefly objects, use a two-second revisit delay, and track active Sparkles under workspace.Flowers. This script batches touches of stationary fireflies in the current field before harvesting sparkling flowers and nearby Collectibles. Autodig continues during farming. Sparkle markers are tracked through descendant events rather than repeatedly scanning the entire flower map.

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

## Standalone repair (fireflies-v2)

The GUI now has editable Walk speed (1–100) and Tween speed (4–12), plus walkspeed enable and Red Cannon toggles. Press Enter or leave a speed input to apply/save. Tween uses the original scale: setting 8 corresponds to 80 studs/second. Cannon access follows the chosen movement mode, while hive claiming always forces walking. Walking uses bounded progress checks and replans stalled waypoints; cannon activation waits briefly for the visible prompt.

Targets are approached directly without a field-centre detour. A firefly is recorded as touched only after physical arrival and a fresh stationary-position check. Sparkles must be enabled and near a recently confirmed firefly touch; unrelated LeafBurst markers and stale/inactive sparkles are ignored. Failed movement does not count as successful harvesting. Field detection uses actual zone bounds.

## Travel and local collection (fireflies-v3)

Movement selects travel between fields only. Tween travels directly to an approach point away from the firefly and never schedules Red Cannon. Local firefly contact, sparkle harvesting and token collection always walk, including with Tween selected. Hive claims always walk too. Walking uses continuous waypoint lookahead, preserves jumps and checks supported ground before cutting corners; stalled routes replan rather than stopping at every short waypoint.

The supplied Atlas selector is retained: stationary BodyVelocity, nearest target and two-second revisit suppression. The local cycle walks through settled fireflies and prioritizes eligible loot before sparkle harvesting. Requested extensions include full-night retention, batched touches, constrained drop collection and main/alt coordination; this is not a copy of Atlas's complete farm engine.

Only newly spawned tokens associated with a recent confirmed touch or sparkle harvest are eligible. Pre-existing field tokens, other-source attributes, ability icons and distant drops are rejected. Without a source attribute, Moon Charm/honey icons plus time and proximity are used as a conservative association; exact provenance cannot be proven for every token.

## Main and alt night-server search

Run this same standalone version on main and alts. Enter the same Group room and Main username in each GUI, then Start. Username matching is case-insensitive. The main farms and remains for the whole night. Alts scout for night servers containing settled fireflies, report them, and continue scouting after the main arrives. Group changes stop the current worker and require Start again. The main joins only fresh reports for its place/room/main and only while searching for night; reports never launch another farm.

Group transport defaults to https://ntfy.sh using a hashed Fireflies topic and the existing text/plain publish/newline-JSON poll protocol. The former relay returned HTTP 403 in a read-only check; ntfy.sh polling returned HTTP 200. RelayURL can be set in the initial options for another compatible service. HTTP request and queue-on-teleport support are needed for cross-account discovery and resume. The room string itself is not sent in report bodies, though this is a public relay service. Live cross-account joining has not been verified.

## Walking and farm efficiency (fireflies-v4)

Within a level field, movement uses one direct MoveTo per target with no path computation, waypoint detours or jumping. Native pathfinding is only an obstacle fallback after a genuine stall. Longer walks use the authored Atlas A* graph (3,439 nodes / 22,048 links), then native pathfinding only if necessary. Flat supported waypoints do not trigger jumps. Healthy progress extends travel deadlines, avoiding failures merely because movement is slower than expected.

The 385,774-byte route data file is downloaded only when an authored walking route is first needed and cached in TifaHop/firefly_walk_routes_v4.luau. The standalone backend remains about 55 KB. Alt scouts do not load this graph. Runtime re-execution reuses the cached route table.

An unmoved, already-touched firefly is not revisited. Movement/relocation makes it eligible again. Delayed sparkle/drop events can restore their harvest field without revisiting old firefly positions. Sparkle farming waits only for a real available tool activation, replacing the fixed 1.2-second pause; background autodig cannot consume the activation while a sparkle is being harvested. Eligible early drops remain associated long enough to collect after the touch batch. Field bounds are cached rather than rebuilt for every candidate.
