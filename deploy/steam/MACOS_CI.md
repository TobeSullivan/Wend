# macOS build → Steam, via GitHub Actions

CI builds, signs, notarizes, and (optionally) uploads the macOS client so you
never touch a Mac. Workflow: `.github/workflows/macos-steam.yml` (manual trigger).

## Where the credentials live

**All secrets go in ONE place:**
GitHub → your repo (`TobeSullivan/Wend`) → **Settings** → **Secrets and variables**
→ **Actions** → **Secrets** tab → **New repository secret** (one per row below).

The non-secret depot id goes in the **Variables** tab (same page).

| Name | Tab | What it is / how to produce it |
|------|-----|-------------------------------|
| `MACOS_CERTIFICATE_P12_BASE64` | Secret | Your **Developer ID Application** cert+key exported from Keychain as a `.p12`, then `base64 -i cert.p12 \| pbcopy` |
| `MACOS_CERTIFICATE_PASSWORD` | Secret | The password you set when exporting that `.p12` |
| `MACOS_NOTARY_KEY_P8_BASE64` | Secret | App Store Connect API key `.p8`, as `base64 -i AuthKey_XXXX.p8` |
| `MACOS_NOTARY_KEY_ID` | Secret | The API **Key ID** (shown next to the key) |
| `MACOS_NOTARY_ISSUER_ID` | Secret | The API **Issuer ID** (top of the Keys page) |
| `STEAM_USERNAME` | Secret | Your Steam **builder** account login |
| `STEAM_CONFIG_VDF` | Secret | Cached Steam login (see "Steam login" below), `base64 -i config.vdf` |
| `STEAM_MACOS_DEPOT_ID` | **Variable** | The macOS depot id you create in Steamworks (e.g. `4884652`) |

> Where those Apple values come from (the portals from before): the cert →
> developer.apple.com/account → Certificates; the API key (`.p8` + Key ID +
> Issuer ID) → appstoreconnect.apple.com → Users and Access → Integrations.

## One-time setup you must do (I can't — they're web/portal actions)

1. **Apple:** create the **Developer ID Application** certificate, export it as
   `.p12` (with its private key) from Keychain on any Mac, and create an
   **App Store Connect API key** (Developer role). Add the 5 Apple secrets above.
2. **Steam — create the macOS depot:** Steamworks → **Wend Playtest (4884650)**
   → **Depots** → add a new depot, set its **Operating System = macOS**, publish
   the change. Put its DepotID in the `STEAM_MACOS_DEPOT_ID` **variable**.
3. **Steam login (`config.vdf`):** on any machine with `steamcmd`, run once:
   `steamcmd +login <builder> <password> <steamguard_code> +quit`. That writes a
   cached session to `…/Steam/config/config.vdf`. Base64 it into `STEAM_CONFIG_VDF`.
   (Use a dedicated builder account; a mobile-authenticator account needs its
   shared secret instead — ask and I'll wire that variant.)

## Run it

GitHub → **Actions** → **macOS build → sign → notarize → Steam** → **Run workflow**.
- Leave **upload_steam** unchecked for a build-only run (produces a signed,
  notarized **`Wend-macos` artifact** you can download + upload like the Windows one).
- Check **upload_steam** to also push to the Steam macOS depot, then set the build
  live in Steamworks → Wend Playtest → **Builds**.

## Good to know

- **Before the Apple secrets exist**, the workflow still runs and produces an
  **unsigned** `Wend-macos` artifact (macOS will warn on launch). Signing +
  notarization + Steam upload auto-activate once the secrets are present.
- The build reflects **committed** code (CI checks out the repo). Commit your game
  changes before the real upload.
- Godot version, GodotSteam addon URL, and bundle id are pinned in the workflow /
  `export_presets.macos.cfg` — bump them there if you upgrade.
