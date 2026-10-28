# Validation

- Official Luau compiler 0.744: runtime and loader compile.
- Twelve normal-interaction cases verify walking before E, strict distance/height checks, visible prompt matching, existing ownership, unavailable routes, other-player ownership, claim races, replication delay and stopping. A false-positive movement return cannot bypass interaction range.
- Static audit: generated runtime contains no ClientCall, FireServer, InvokeServer, flying AlignPosition construction, old direct claim callbacks, fake fighting-platform identifier, or explicit root position/CFrame assignments. Remaining UI tweens are retained.
- Ground-combat tests verify MoveTo movement, observed reward accounting and cleanup on Stop without the former flying/platform callbacks.
- Full map: 3,439 nodes and 22,048 baseline links; 30 A* route results match independent Dijkstra costs. Mocked route tests cover blocked links, stalls, moving targets, elevated roots, missing connectors, death and cancellation.
- Cannon planner tests select shortcuts when enabled and walking when disabled. Mocked cannon execution covers range/prompt handling, launch/landing failures, Stop and glider input. The common normal-interaction tests enforce the actual E-key guard.
- Fireflies tests cover stationary targets, revisit suppression, field filtering, loot callbacks, night/day hopping, DontHop, stop cleanup and hive-first mode dispatch.
- Configuration and startup regressions cover persistent modes, account roles, walking-only normalization, keyless startup, duplicate prevention and error recovery. Twenty-three isolated pure helpers still match the original interpreter.

Tests use mocked game services. They do not establish successful live traversal/combat, availability of external services, game approval of automation or protection against bans.
