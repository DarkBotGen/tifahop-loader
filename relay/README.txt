TifaHop Relay - Windows 10/11, 64-bit Intel/AMD

1. Extract this folder on the laptop. Double-click START.cmd.
2. Setup downloads portable Python and cloudflared from their official release
   servers and verifies pinned SHA256 hashes. No Python installation, admin
   access, firewall rule, router forwarding, or Cloudflare account is needed.
3. YOUR-RELAY-URL.txt opens with your private HTTPS base URL. Copy the WHOLE
   URL, including its long secret path, into RelayURL on main and all alts.
4. Keep the relay window open. Ctrl+C stops the relay and tunnel.

Install location: %LOCALAPPDATA%\TifaHopRelay
Current URL:      %LOCALAPPDATA%\TifaHopRelay\YOUR-RELAY-URL.txt
Settings:         %LOCALAPPDATA%\TifaHopRelay\settings.json

Reliability:
- Manager restarts exited relay/tunnel processes while it is running.
- Optional: run ENABLE-AUTOSTART.cmd after setup. This starts the manager
  hidden at your next Windows sign-in, not before anyone logs in. Disable with
  DISABLE-AUTOSTART.cmd. Background output is in manager.log in install folder.
- In Windows power settings disable sleep while plugged in; if closing the lid,
  set its plugged-in action to Do nothing. Keep laptop plugged in and online.
- Quick Tunnels have no uptime guarantee and change URL when recreated. After
  a tunnel restart, copy the new URL into all accounts and restart the scripts.
  This is a convenient starter mode, not a promise of permanent 24/7 hosting.

Permanent URL (requires a Cloudflare account and domain):
Create a remotely managed Cloudflare Tunnel in the dashboard. Configure its
public hostname (for example relay.yourdomain.com) to service
http://127.0.0.1:8787. Put its connector token in TunnelToken in settings.json,
and https://relay.yourdomain.com in PublicURL. Stop and restart START.cmd.
The generated base URL still includes the secret path. Keep that path.
For a named tunnel, URL is displayed before the external route is verified;
check https://your-host/your-secret/health for {"ok":true,...}.

Compatibility:
POST <RelayURL>/<topic> accepts a JSON message as text/plain.
GET <RelayURL>/<topic>/json?poll=1&since=30s returns newline JSON envelopes
with id/time/event/topic/message. since also supports message IDs and all.
Works with normal TifaHop Walk/Tween relay protocol and standalone Fireflies.
Use the same RelayURL, Group, and MainAccount on every cooperating account.

Privacy/limits:
The secret URL grants access; keep it private. Reports are held only in RAM
for five minutes (max 256 topics, 256 messages/topic), lost on relay restart.
Payload cap 32 KiB; max 64 active local request handlers. Server listens only
on loopback; the tunnel exposes only this relay, not other laptop services.
No account passwords/cookies are required. Never paste them into settings.

Troubleshooting:
- Download errors: internet/security software may block Python or GitHub.
- No URL: allow cloudflared outbound access; check manager.log in background
  mode. Existing .cloudflared config can interfere with Quick Tunnels.
- Port conflict: change Port in settings.json; named tunnel origin must match.
- ARM or 32-bit Windows/Linux: this package does not target those platforms.
- Removing auto-start does not terminate already running processes. Stop the
  foreground manager with Ctrl+C; sign out to stop a background login session.

Cloudflare: https://developers.cloudflare.com/tunnel/get-started/quick-tunnels/
