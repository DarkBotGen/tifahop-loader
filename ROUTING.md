# Routing and normal interactions

The user supplied atlasbss (1).lua as a reference. Only literal route coordinates, walking links and Red Cannon timing profiles were extracted; that script was not executed. Baseline map travel uses A* with a binary heap, visible connectors and bounded retries that exclude stalled edges. Optional cannon shortcuts use a time-based cost. Other cannon, portal, reset and specialized interaction edges are omitted.

The recovered general walking branch immediately aborted; it has been replaced with the map router. The former flying movement function is replaced too, so legacy callers cannot teleport or fly when a stale UI value says Tween. Scripted speed overrides, fast token tweens, direct interaction remotes and the old Vicious platform routine are omitted or replaced.

Hive claiming uses an empty hive's patharrow.Base position, forces a walking-only route, and checks actual proximity and the visible Claim Hive prompt before sending E. It confirms ownership and spawn readiness before starting either grind mode. No direct ClaimHive call remains.

Vicious approach resolves the containing field, travels to that field and then walks below the elevated bee. Combat circles on the ground with MoveTo and the normal token collector. Red Cannon interaction requires the physical platform and a matching on-screen prompt, with no remote activation from a distant location. Fireflies use the same field travel and normal collection helpers.

The static map reflects the supplied reference version. Geometry changes, streaming, collision and character jump capability still affect real traversal. Mocked tests cannot reproduce the live game.
