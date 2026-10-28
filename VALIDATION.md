# Validation

- Official Luau compiler: all three backends and their loaders compile independently.
- Standalone Firefly worker tests verify touching both stationary fireflies before sparkle harvesting, harvesting Sparkles with digging, retaining empty night servers, hopping only at dawn/day, and DontHop behavior.
- Autodig tests verify normal tool equipping/activation and no activation while dead.
- Hive tests verify nearest vacant slot selection independently of slot enumeration order, occupied slot exclusion, fallback after unreachable routes and ownership races, proximity/prompt requirements, target disappearance cancellation and no empty-server claim.
- Static checks verify that the two other backends contain no Fireflies tab or worker, and that standalone Fireflies contains no recovered Functions VM or other farm workers. Both PathfindingService and TweenService are present in standalone.
- Existing map navigation, cannon execution, movement cancellation, ground combat, speed persistence and selected-farm persistence tests cover the shared helpers.

Tests mock Roblox services. Live gameplay and executor teleport resume are not established by these checks.

- Standalone repair tests verify editable/saved speed values and invalid-input handling; original tween scale (100 studs at setting 8 takes 1.25 seconds); cancellation; selected movement for cannon access versus forced walking for hives; strict field bounds; rejection of disabled/unrelated sparkles, unvisited locations, false arrival and targets moving before contact. These remain mocked checks, not successful live-game verification.

- fireflies-v3 tests verify continuous waypoint merging, preserved jump execution, bounded replanning and Stop cancellation; off-target inter-field arrival followed by forced walking contact; no cannon scheduling in Tween; local forced walking; rejection of pre-existing, ability, foreign-source, distant and expired tokens; main/alt role selection; room/place/night/freshness report validation; relay wire protocol; and scout departure after the main arrives.
- Transport checks were read-only: former relay returned HTTP 403; ntfy.sh polling returned HTTP 200. No group report was published in these checks. Cross-account discovery/teleport behavior remains mocked rather than live-verified.

- fireflies-v4 regressions verify one direct command per local target with zero ray scans/path computations/jumps; a complete cached authored route from the cannon area to Mountain Top without native pathfinding; no jump at flat supported native waypoints; one visit per unmoved firefly; recovery of delayed sparkles after leaving the touch phase; and removal of the fixed 1.2-second harvest pause. Final backend and separate route data compile. These tests remain mocked and do not confirm live performance.
