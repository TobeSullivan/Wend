# Wend — Steam SDK (GodotSteam) integration

GodotSteam **GDExtension v4.19.1** (Steamworks SDK 1.64), drop-in at `src/addons/godotsteam/`.
Stock Godot editor + stock export templates (no engine recompile). MIT.

Three phases were implemented. **Phase 1 is verified.** Phases 2–3 are code-complete but their
end-to-end paths can only be verified on a build **launched through Steam while online** (see
"Verification status").

---

## Install the addon (required — it's gitignored)

`src/addons/godotsteam/` is **not committed** (94 MB of binaries; treated like export templates).
A fresh checkout must fetch it, or the project won't compile (`steam_manager.gd` references the
`Steam` singleton). Get the exact version this project targets:

```powershell
# GodotSteam GDExtension v4.19.1-gde (Godot 4.4+, Steamworks SDK 1.64)
$zip="$env:TEMP\godotsteam.zip"
Invoke-WebRequest -Uri 'https://codeberg.org/godotsteam/godotsteam/releases/download/v4.19.1-gde/godotsteam-4.19.1-gdextension-plugin-4.4.zip' -OutFile $zip
Expand-Archive -Path $zip -DestinationPath "$env:TEMP\godotsteam" -Force
Copy-Item -Recurse -Force "$env:TEMP\godotsteam\addons\godotsteam" "C:\dev\Wend\src\addons\"
```
Then open the project in Godot once (or run `Godot --headless --path src --import`) to register the
extension. Source / other platforms: <https://codeberg.org/godotsteam/godotsteam/releases>.

## What's in the project

- `src/addons/godotsteam/` — the GDExtension (all platforms incl. macOS-universal) + Steam redistributables.
- `src/steam_appid.txt` = `4884650` — lets the editor / a locally-run export init Steam without
  launching through Steam. **Excluded from the shipped depot** (export preset `exclude_filter`).
- `src/scripts/steam_manager.gd` — `SteamManager` autoload (registered before `NakamaService`):
  - **Phase 1:** `steamInitEx` + per-frame `run_callbacks()`, graceful no-Steam fallback,
    identity (`get_steam_id()`, `get_persona_name()`), overlay (`open_overlay()`), `overlay_toggled`.
  - **Phase 2:** `get_web_api_ticket_async()` → hex web-API auth ticket for login.
  - **Phase 3:** `unlock_achievement()`, `set_stat_int/float()`, `store_stats()`, `stats_ready`.
- `src/scripts/nakama_service.gd` — `connect_backend()` now tries **Steam → device** auth
  (persisted session first, Steam identity second, device auth fallback). `_http_key` added.
- `deploy/nakama/data/modules/index.js` — `steam_auth` RPC (see Phase 2 below).
- `deploy/nakama/docker-compose.yml` + `.env.example` — Steam runtime env.

The Windows export bundles `Wend.exe`, `Wend.pck`, `libgodotsteam.windows.template_release.x86_64.dll`,
and `steam_api64.dll` — all four upload to the depot (the depot VDF maps `*` recursively).

---

## Phase 2 — why a custom RPC (important)

Nakama's **built-in** `authenticate_steam` does **not** work with modern Steam tickets. Steamworks
SDK 1.57+ rejects old `GetAuthSessionTicket` tickets for web validation; the replacement,
`GetAuthTicketForWebApi`, **requires a non-empty `identity`** — and Nakama's built-in validator
calls `ISteamUserAuth/AuthenticateUserTicket` **without** the `identity` param (verified in Nakama
source), so validation fails.

So login goes through a custom RPC instead:

1. Client `SteamManager.get_web_api_ticket_async()` → `getAuthTicketForWebApi("wend-nakama")` → hex ticket.
2. Client calls the no-session RPC `steam_auth` (via the runtime `http_key`) with `{ticket, identity}`.
3. Server (`index.js` `rpcSteamAuth`) validates the ticket **with** the identity, then
   `authenticateCustom("steam:"+steamId)` + `authenticateTokenGenerate` → returns a session token.
4. Client builds a `NakamaSession` from that token.

The client identity (`SteamManager.WEB_API_IDENTITY = "wend-nakama"`) **must equal** the server
`STEAM_IDENTITY`. Both default to `wend-nakama`.

---

## YOUR action items to make Phase 2/3 live

### 1. Create a Steam publisher Web API key
Steamworks → **Users & Permissions → Manage Groups** → your group → **Create Publisher Web API Key**.
(This is a *publisher* key, not a personal user key.) Put it on the box in `deploy/nakama/.env`:
```
STEAM_PUBLISHER_KEY=<the key>
STEAM_APP_ID=4884650
STEAM_IDENTITY=wend-nakama
```
Until this is set, the server returns "not configured" and clients silently fall back to device auth
(nothing breaks).

### 2. Deploy the Nakama changes (live Hetzner box)
The `index.js` RPC + compose env change must reach the box, then restart:
```bash
# copy deploy/nakama/{docker-compose.yml,data/modules/index.js,.env} to the box, then:
docker compose up -d        # picks up the new --runtime.env
docker compose restart nakama
docker compose logs -f nakama   # expect: "Wend runtime loaded: ... + submit_score RPC ..."
```
The default runtime `http_key` is `defaulthttpkey` (Nakama default) — the client uses that. If you
set a custom `--runtime.http_key`, mirror it as `http_key=` in the client's `src/nakama_local.cfg`.

### 3. Cloud saves (Steam Auto-Cloud — no code)
Wend saves to `user://save.json` → on Windows `%APPDATA%\Godot\app_userdata\Wend\save.json`.
Steamworks → **(Playtest app) → Cloud / Auto-Cloud** → add a root + pattern:
- Root: `WinAppDataRoaming`, Path: `Godot/app_userdata/Wend`, Pattern: `save.json`
- (macOS later: root `MacHome`, path `Library/Application Support/Godot/app_userdata/Wend`)
Then enable Steam Cloud and set a per-user byte quota.

### 4. Achievements / stats (Phase 3)
The client helpers exist but do nothing until you **define achievements/stats in Steamworks**
(Stats & Achievements), then call e.g. `SteamManager.unlock_achievement("ACH_FIRST_WIN")` from game
code by the API name you set there. No achievements are wired yet — that needs a design pass on
*which* achievements (out of scope for code).

---

## Verification status

| Item | Status |
|---|---|
| Extension loads in editor + exported release build | ✅ verified |
| `steamInitEx` success (editor, with `steam_appid.txt`, Steam running) | ✅ verified — `Irish Whiskey (76561198059480701)` |
| Graceful fallback when Steam absent / no appid | ✅ verified — exported exe logs "Game continues without Steam", exit 0 |
| Steam DLLs bundled next to the exe in export | ✅ verified |
| Device-auth fallback path intact | ✅ verified (unchanged) |
| Steam **overlay** in-game | ⏳ Steam-launched build only (Vulkan/editor limitation per GodotSteam) |
| **Web-API auth ticket** issuance | ⏳ blocked locally: this machine's Steam reports `BLoggedOn()=false` (Offline Mode / not connected). Tickets require a fully online, Steam-launched session. |
| **Phase 2 end-to-end login** (client RPC ↔ server validate) | ⏳ pending: publisher key + server deploy + an online Steam-launched client |
| **Phase 3** achievements/stats | ⏳ pending: define them in Steamworks first |

To close the ⏳ items: upload the build, install it via Steam, ensure your Steam client is **online**,
launch, and watch the client log for `steam_auth ok` (server) / a Steam session (client), and test
Shift+Tab for the overlay.
