# Validation

- Official Luau compiler 0.744: complete TifaHop runtime and loader compile successfully.
- Final branded runtime: all 23 isolated differential cases match the original interpreter and independently expected results.
- Configuration adapter: 36 assertions cover account roles, room handling, saved configuration, invalid inputs, authoritative startup settings, branding, movement modes, Fireflies mode persistence/independent roles and Red Cannon options.
- Hosted loader: explicit options are forwarded unchanged, no-argument defaults work, and the backend is cached to the expected rejoin path.
- Keyless startup: direct automation initialization, old prompt cleanup, duplicate-start prevention, failure reporting and retry tested with mocks. License module and all its descendants are absent; all remaining function references resolve.
- Hive-first sequence: 12 mocked cases cover existing ownership, successful claiming, delayed replication, false-positive claim returns, transient errors, platform ownership, other-player ownership, delayed spawn readiness, stop/cancellation, stale references and unavailable claim callbacks. Generated-code tests verify that Vicious search and combat do not enter their original logic until the gate succeeds.
- Current map router: 12 mocked scenarios cover walking, jumping, blocked-link detours, moving targets, stalls, stop cancellation, target disappearance, character death/respawn, elevated Vicious roots, disconnected graphs, missing connectors and short local walking.
- Full reference graph: 3,439 coordinates and 22,048 walking links, all references valid. Thirty sampled full-map A* routes match independent Python Dijkstra distances.
- Generated-code integration: general travel invokes the replacement map router. Vicious Walk calls navigation; Tween calls the original flying callback. The ground-arrival calculation preserves the original 3D check in Tween mode.
- Red Cannon: full-map planning tests verify shortcut selection when enabled and walking when disabled. Mocked execution covers activation, a locked prompt, missed landing, stopping and the glider input sequence.
- Fireflies: mocked tests cover nearest stationary targets, revisit/blocked-target suppression, field filtering, farming and token collection callbacks, night/day hopping, DontHop and stop cleanup. Generated-mode tests verify hive claiming precedes Firefly work and the Vicious search path is not entered.
- All 516 function control-flow partitions and jump destinations verified during reconstruction.

Tests use mocked game/filesystem services. They do not launch automation or contact the relay. Live operation, executor-specific behavior and remote service availability remain unverified.
