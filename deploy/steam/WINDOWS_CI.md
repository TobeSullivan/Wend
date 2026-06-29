# Windows → Steam playtest, hands-off

`.github/workflows/windows-steam.yml` exports the Windows client on CI, uploads
it to the Steam Windows depot (`4884651`), and sets the build live on your
playtest branch. No local export, no web tool, no per-push manual step.

## Secrets / variables (GitHub → Settings → Secrets and variables → Actions)

| Name | Tab | What it is |
|------|-----|-----------|
| `STEAM_USERNAME` | Secret | Your Steam builder account login |
| `STEAM_CONFIG_VDF` | Secret | Cached Steam login (see below), base64-encoded |
| `STEAM_BETA_BRANCH` | **Variable** | The Steam branch testers get (e.g. `default` or `playtest`). Blank = upload only, you flip it. |

I never see these — GitHub injects them into the runner at build time only.

## One-time: the cached Steam login (the ONLY manual step, ever)

On any machine with `steamcmd`, log in once to cache the session (this is the
SteamGuard step — done a single time, never again):

```
steamcmd +login <builder> <password> <steamguard_code> +quit
```

Then base64 the resulting `config.vdf` into the `STEAM_CONFIG_VDF` secret:
- Win: `[Convert]::ToBase64String([IO.File]::ReadAllBytes("$env:USERPROFILE\.steam\config\config.vdf"))`
  (or wherever steamcmd wrote it — typically `<steamcmd>\config\config.vdf`)
- Mac/Linux: `base64 -i config.vdf`

The builder account needs **Edit App Metadata / Publish** on app `4884650`.

## Shipping a build (zero manual time)

```
git tag playtest-1 && git push origin playtest-1
```

That's it — the tag triggers export → upload → set-live, and testers get it when
the run finishes. (Or use Actions → Run workflow for a one-click manual build.)
Tag names: anything starting `playtest-` or `v`.

> First-ever build still needs Steam's one-time review; after that, tagged
> playtest builds go live without re-review.
