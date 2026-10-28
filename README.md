# TifaHop

Configurable Luau loader and recovered runtime.

Copy `loader.luau` into your executor and edit only these settings:

```lua
local Config = {
    MinViciousLevel = 1,
    MaxViciousLevel = 12,
    DontHop = false,
    MainAccount = "YourMainUsername",
    Group = "YourSharedRoom",
}
```

Or launch the hosted loader directly with those same five controls:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/DarkBotGen/tifahop-loader/refs/heads/main/loader.luau"))({
    MinViciousLevel = 1,
    MaxViciousLevel = 12,
    DontHop = false,
    MainAccount = "YourMainUsername",
    Group = "YourSharedRoom",
})
```

- Vicious levels are inclusive integers from 1 to 12; minimum cannot exceed maximum.
- `DontHop = true` sets the original script's no-hop setting. Its separate error/rejoin recovery still exists.
- `MainAccount` is the Roblox **username**, not display name. Matching is case-insensitive. The matching account is main; other accounts using the same group are alts.
- Use the same `MainAccount` and `Group` on every participating account. A nonempty group requires a main username.
- Empty `Group` disables grouped roles. Group is this script's shared coordination room, not a Roblox group ID. Room names are not authenticated access controls.

The loader downloads `TifaHop.luau` and calls it with the configuration table. It caches the backend as `TifaHop/source_premium.lua` for the original rejoin bootstrap. Each account's loader configuration is saved under `TifaHop/loader_<UserId>.json`; the cached backend can reload it when a server transition starts a new session.

The requested controls override the old saved settings at startup. Other features retain the recovered defaults and original UI controls. This does not remove UI tabs or features from the underlying program.

## Environment and validation

Requires the original Roblox/executor APIs, filesystem/HTTP capabilities, key system and remote services. Branding, local paths and internal session prefixes use TifaHop. The existing third-party relay endpoint is preserved; it has not been moved or replaced by this repository.

The full runtime and loader compile with the official Luau compiler. The preceding runtime reconstruction passed 23 isolated differential tests against its original interpreter. Loader configuration, account roles and persistence are tested with mocked services. Live Roblox automation and the external relay have not been tested.

`build_map.json` preserves original function IDs and instruction block addresses for inspection. Source uses a program counter in place of unsupported goto syntax.
