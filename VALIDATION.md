# Validation

- Official Luau compiler 0.744: complete TifaHop runtime and loader compile successfully.
- Final branded runtime: all 23 isolated differential cases match the original interpreter and independently expected results.
- Configuration adapter: 22 assertions cover main/alt role assignment, username case/whitespace, room handling, saved configuration recovery, invalid input rejection, authoritative startup settings, and branding.
- Hosted loader: explicit options are forwarded unchanged, no-argument defaults work, and the backend is cached to the expected rejoin path.
- Keyless startup: direct automation initialization, old prompt cleanup, duplicate-start prevention, failure reporting and retry tested with mocks. License module and all its descendants are absent; all remaining function references resolve.
- Walking approach: 10 mocked scenarios cover walking and jump waypoints, blocked-route and moving-target replans, no-path/computation failures, stalled movement, stop cancellation, target disappearance, character death and already-near targets. All path/move connections are checked for cleanup. An integration test executes the generated Vicious routine up to its approach and confirms it calls the navigator, not the flying callback.
- All 516 function control-flow partitions and jump destinations verified during reconstruction.

Tests use mocked game/filesystem services. They do not launch automation or contact the relay. Live operation, executor-specific behavior and remote service availability remain unverified.
