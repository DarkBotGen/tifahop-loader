# Walking route implementation

Reference: `atlasbss (1).lua`, supplied by the user. Only its static route coordinates and standard walking/jumping links were extracted; the reference script was not executed.

The reference's relevant sections are its map-graph planner near line 6694, route follower near line 7023, path links near line 7689, node coordinates near line 36596 and Vicious routine near line 58277. Its Vicious routine locates the containing flower field and calls field travel before moving near the target. The root position is used with a downward offset when selecting ground combat positions.

The preceding TifaHop version instead sent Roblox's generic pathfinder toward the boss and compared full 3D distance with its elevated root. In addition, the original general walking callback (`main_0_38`) immediately raised the internal return sentinel, so the global Walk selector had no usable route implementation.

The replacement uses a custom binary-heap A* planner on 3,439 route nodes and 22,048 directed links. Candidate endpoints must have an unobstructed connector through Map/Gates geometry. The follower refreshes Humanoid MoveTo, triggers jumps for labelled transitions, measures horizontal progress with a vertical arrival bound, and excludes stalled links for subsequent attempts. It stops after four route attempts or its time budget. No health reset, noclip, teleport, cannon or portal action is introduced by the router.

Special interaction links are excluded from the baseline graph. Red Cannon routes are optionally added separately using four entry nodes, 21 reference timing profiles and estimated travel-time costs. Blue/Yellow cannons, portals and reset links remain excluded. Optional jump shortcuts are not merged; required jump links already present in the baseline graph are retained. Specialized areas reachable only through excluded interactions may have no walking route.

Vicious movement routes to the target field and then to a grounded position beneath the current boss position. The containing field is checked again if the boss moves. Existing combat and its platform remain intact after arrival.

The map data comes from the supplied reference version. Live geometry, streaming, collision changes and character jump capability can still affect traversal; mocked tests cannot verify those in-game conditions.
