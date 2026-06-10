# Open items — backlog ledger

**Delete-on-done.** This file holds only OPEN work. When something resolves, delete it; if it
encodes a must-not-reverse call, promote that one line to `notes/decisions.md` first. The history
of resolved items lives in `STATE_ARCHIVE.md`. STATE.md's "Open questions" points here.

Status key: **OPEN** · **BLOCKED-DATA** · **PARKED** (additive, not now) · **OWN-SESSION** (large)

---

## Steam (ops) — blocked on verification
- **Identity verification pending** (2–7 biz days from 2026-06-07, third-party Lilaham/TaxIdentity). Blocks finishing account creation + creating the App ID/Playtest. $100 Direct fee paid → 30-day release clock running (earliest ~2026-07-07).
- **Confirm the entity type** chosen at registration (individual vs company — matters for tax/bank + later restructure).
- **When it clears:** create the Wend App ID → create the Playtest app **confidential/friends-only** (Playtest App ID + Standard Release keys + Playtest Playable + Store Visibility Hidden; hand keys directly to testers). Public Coming Soon page is gated on the beta art read, not now.

## Cosmetics — open forks (not blocking)
- **Score task:** cumulative across the window vs best single run.
- **Active task count:** all 15 (5 shapes × 3 cadences) at once vs a rotating subset.
- **Confirm** the free Background Creator pack actually yields path tiles before relying on it for the board slot.

## Deploy / ops (CC)
- **Beta-season boards:** `index.js` board init needs a separate beta season + beta-flagged Trials (`ranked_s0`) so the closed beta never touches launch's `s1` (launch opens clean by construction).
- **Beta `LOBBY_FLOOR = 2`** in `index.js` (vote path unchanged), with a **documented revert to 4 at launch**. Must not ship to launch at 2.

## CC — carried (not blocking; do as items are promoted)
- Export a **catapult PNG body** (`towers/catapult/` ships SVG only).
- Import alt **mobs** (fish / slime / starfish) and alt **biomes** (beach / bog) into `src/assets/` as catalogue items are promoted. Skins live in the client render layer only — never route equipped-skin state through the match record (breaks re-sim determinism).
- Build the **board-sticker render layer:** chrome-edge placement, runtime outline tint per tier, animated multi-color stroke for Masters; toggle; never overlaps the play area.
- **`src/tools/rescale_campaign.gd:18`** still targets `Vector2i(25, 14)` — should be `25, 16` (found in the 2026-06-09 audit).
- **Tutorial anchor check (playtest):** beat anchors (`score`/`respawn`/`tower`/`board`) resolving in the new right-rail HUD isn't auto-testable; `tutorial_callout._anchor_panel` still maps `score`/`upgrade_panel` to the OLD top-bar/right-dock positions — re-check against the rail layout in playtest. Also M1's blocking opener pause→resume.
- **Low-pri cosmetic:** `design/DESIGN_MODES.md` schema block still uses literal field names `bronze_threshold`/`silver_threshold`/`gold_threshold` (these are the 1/2/3-star cutoffs). Rename to star-N someday; not worth a churn now.

## Own session (large)
- **Finalize season-pass numbers** — `notes/season_pass.md` has a soft 8wk/30-tier/1000pt worked example; now the catalogue + slots + task system exist, the actual tier-by-tier reward mapping can be laid out. Upstream-clear.
- **Full GTM / marketing plan** — `notes/gtm.md`. **Steam-gated end to end:** the public page is gated on the beta art read, which is gated on people playing the build, which is gated on Steam. No meaningful GTM work survives upstream of the art read (this kept resurfacing as here-doable — it is not). Capsule (~$250+) is the one paid item worth prioritizing once the page is unblocked.
- **Steam closed-beta ops pipeline** — mechanics are designed (`notes/beta_design_brief.md`); what remains is the Steam-side build pipeline: App ID, Playtest app, Win+Mac export presets, steampipe. Blocked on verification clearing.

## Blocked on playtest data
- **Star-threshold calibration** (Campaign + Trials).
- **Economy/supply re-tune** for the 25×16 board.
- **Campaign tuning integers** — supply/rounds/mobs/zone-mix for the five missions; wait on the 25×16 retune + real scores.
- **PVP seed-convergence** — shared-seed ranked could converge to identical mazes; eyeball in playtest.

## Parked — additive, not now
- **Individual-while-grouped Trials scoring** — a future vote letting grouped players each post to Solo instead of team score. Group size = the board for now.
- **Ranked ready-check** — ships off; flip on only if AFK-poisoning shows in beta.
- **Match reconstruction after coordinator crash** — model is re-simmable, but crash currently voids with no LP instead.

## Drift / audit
- **Open call for Tobe:** `notes/multiplayer_architecture.md` is an older topology-analysis doc whose verdict column still marks P2P host-auth as "✅ Best beta path." That contradicts the deployed reality (dedicated-authoritative is live and used for the beta per "no disposable intermediates"). The codes→Steam-invite cells were corrected in the 2026-06-09 audit, but the verdict column's recorded *conclusions* were left as-is — decide whether to rewrite them or keep the doc as a historical analysis.
- (Resolved in the 2026-06-09 audit, no longer tracked: the 4-digit room-code sweep, the 40×22 / 25×14 grid-figure sweep, the 10-mission references, the "Maze Battle TD" title, the stale in-match-HUD subsection in DESIGN_MODES.)
