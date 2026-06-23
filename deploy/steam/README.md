# Wend Playtest — Steam (SteamPipe) upload

Exports the **Windows client** and uploads it to the **Wend Playtest** depot via SteamPipe.

- Parent app: **Wend** `4884610`
- Playtest (child) app: **Wend Playtest** `4884650`  ← builds upload here
- Depot: **Wend Playtest Content** `4884651` (already created by Steam; wired into both `.vdf` files)

> No Steamworks SDK / GodotSteam in this build by design — Steam build review only needs a
> build that launches. Overlay/achievements/cloud are a later, separate task.

---

## 0. One-time prerequisites (already done on this machine)

- Godot **4.6.3** + Windows x86_64 export templates installed.
- `steamcmd` at `C:\steamcmd\steamcmd.exe`.
- Windows Desktop export preset in `src/export_presets.cfg` (preset is gitignored — machine-local;
  recreate via Project → Export → Add → Windows Desktop if missing. Key settings:
  `Architecture = x86_64`, `Embed PCK = OFF` (separate `.pck` → small delta re-uploads),
  `Export Path = ../deploy/build/win/Wend.exe`, **Resources → Include = `nakama_local.cfg`**
  — without that include the backend config is NOT packed and **PVP is silently disabled**).

## 1. Depot ID — done

Depot `4884651` ("Wend Playtest Content") is already created and wired into both `.vdf` files.

## 2. Build the Windows client

```powershell
# from repo root
& "C:\Users\tobes\Desktop\Godot.exe" --headless --path src --export-release "Windows Desktop" "../deploy/build/win/Wend.exe"
```

Output: `deploy/build/win/Wend.exe` + `Wend.pck`. Smoke-test it boots (no Nakama warning =
config packed correctly):

```powershell
& "C:\dev\Wend\deploy\build\win\Wend.exe" --quit-after 180
```

## 3. Upload to SteamPipe

```powershell
& "C:\steamcmd\steamcmd.exe" +login <steam_username> +run_app_build "C:\dev\Wend\deploy\steam\app_build.vdf" +quit
```

First login prompts for your Steam Guard code. The account must have **Edit App Metadata /
Publish** permission on the Playtest app.

## 4. Set live + submit for review (Steamworks web)

1. Steamworks → Wend Playtest → **Builds**: the new build appears. Set it live on your
   beta/default branch (`setlive` is empty in the VDF so this is manual the first time).
2. Complete the **build checklist**.
3. **Submit for review** (3–5 business days; budget for one re-review).

> Note: the Playtest can't be set **Playable** until ~mid-July (21 days after app-credit purchase).
> Build upload + review can proceed before then — it just can't go live to testers until it clears.

## PVP dependency

Testers can only matchmake if the backend is up during the test window:
- Nakama + the match server on the Hetzner box (`5.78.110.182`) running (see `../README.md`).
- The build is compiled against that host via the packed `src/nakama_local.cfg`.
