# Validation

- Official Luau compiler 0.744: complete TifaHop runtime and loader compile successfully.
- Final branded runtime: all 23 isolated differential cases match the original interpreter and independently expected results.
- Configuration adapter: 30 assertions cover main/alt role assignment, username case/whitespace, room handling, saved configuration recovery, invalid input rejection, authoritative startup settings, branding, movement-mode defaults and persistence, general movement selection and invalid movement modes.
- Hosted loader: explicit options are forwarded unchanged, no-argument defaults work, and the backend is cached to the expected rejoin path.
- Keyless startup: direct automation initialization, old prompt cleanup, duplicate-start prevention, failure reporting and retry tested with mocks. License module and all its descendants are absent; all remaining function references resolve.
- Current map router: 12 mocked scenarios cover walking, jumping, blocked-link detours, moving targets, stalls, stop cancellation, target disappearance, character death/respawn, elevated Vicious roots, disconnected graphs, missing connectors and short local walking.
- Full reference graph: 3,439 coordinates and 22,048 walking links, all references valid. Thirty sampled full-map A* routes match independent Python Dijkstra distances.
- Generated-code integration: general travel invokes the replacement map router. Vicious Walk calls navigation; Tween calls the original flying callback. The ground-arrival calculation preserves the original 3D check in Tween mode.
- All 516 function control-flow partitions and jump destinations verified during reconstruction.

Tests use mocked game/filesystem services. They do not launch automation or contact the relay. Live operation, executor-specific behavior and remote service availability remain unverified.
