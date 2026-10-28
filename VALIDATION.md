# Validation

- Official Luau compiler 0.744: runtime and loader compile.
- Twelve normal-interaction cases verify walking before E, strict distance/height checks, visible prompt matching, existing ownership, unavailable routes, other-player ownership, claim races, replication delay and stopping. A false-positive movement return cannot bypass interaction range.
- Static audit: generated runtime contains no ClientCall, FireServer, InvokeServer, flying AlignPosition construction, old direct claim callbacks, fake fighting-platform identifier, or explicit root position/CFrame assignments. Remaining UI tweens are retained.
- Ground-combat tests verify MoveTo movement, observed reward accounting and cleanup on Stop without the former flying/platform callbacks.
- Full map: 3,439 nodes and 22,048 baseline links; 30 A* route results match independent Dijkstra costs. Mocked route tests cover blocked links, stalls, moving targets, elevated roots, missing connectors, death and cancellation.
- Cannon planner tests select shortcuts when enabled and walking when disabled. Mocked cannon execution covers range/prompt handling, launch/landing failures, Stop and glider input. The common normal-interaction tests enforce the actual E-key guard.
- Fireflies tests cover stationary targets, revisit suppression, field filtering, loot callbacks, night/day hopping, DontHop, stop cleanup and discovery-first mode dispatch. Empty, daytime and moving-target cases never claim a hive.
- Deferred-hive tests cover absent targets, missing validators, dead targets, disappearance during walking, and selected-target gates for Vicious, sprouts, Windy and Mondo.
- Configuration and startup regressions cover persistent modes, account roles, walking-only normalization, keyless startup, duplicate prevention and error recovery. Twenty-three isolated pure helpers still match the original interpreter.

Tests use mocked game services. They do not establish successful live traversal/combat, availability of external services, game approval of automation or protection against bans.

- Speed tests verify toggle/value persistence, reload, application, disable restoration, respawn and invalid values. Dodge tests verify warning disks, spikes, clear-route filtering, blocked exits and invisible-marker filtering.

- GUI integration checks cover Fireflies page/tab registration, shared Start/status visibility, native stop/save/selection callbacks and a dedicated worker using the run cancellation token. UI layout and gameplay have not been verified in Roblox.

- Fireflies Start regression executes the complete generated dispatcher with its real boxed run-ID representation, then the actual Fireflies worker against spawned nighttime targets. It verifies hive claiming, travel, collection and cancellation before worker startup. The dispatcher now passes the numeric run ID to the active check.

- Movement regression covers Tween speed, cancellation on Stop/mode switch/death, Movement UI settings, and walking-only hive claims. Cannon preference tests cover committed launch routing, exact destination steering, Pepper exclusion, local movement and launch failure without a walking detour.
