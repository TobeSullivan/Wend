# WRAP — 2026-06-09 (cosmetics: catalogue + curation + season/tasks + stickers)

This file commits into the repo at `notes/wrap.md`. NEXT SESSION: apply the STATE.md +
open_items.md section edits below, do the hygiene audit, then DELETE `notes/wrap.md`.
Apply order now: save this batch into Downloads, run the deploy one-liner (it carries wrap.md in).

---

## Files in this batch

NEW:
- `design/SEASON.md`
- `notes/task_system.md`
- `notes/asset_catalog.md`
- `notes/gds_catalog.csv`
- `notes/asset_buy_list.md`
- `notes/tools/gds_catalog.py`
- `notes/tools/gds_sheets.py`

MODIFIED:
- `design/COSMETICS.md` (supply principle, runtime-tint rule, board-sticker slot, Ranked bundle)
- `STATE.md` (section edits below)
- `notes/open_items.md` (section edits below)

---

## STATE.md — paste this wrap block at the TOP of the session-wrap stack

> **Session wrap 2026-06-09 (design — cosmetics catalogue + full curation + season/task system + rank stickers):** Closed the cosmetics contents work end to end. **Catalogue built from a real scrape** (not eyeballing): two stdlib scripts — `notes/tools/gds_catalog.py` (pack-level index → `notes/gds_catalog.csv`, 1277 packs, name/id/price/GDS+-price) and `gds_sheets.py` (per-slot labeled thumbnail contact sheets) — both run by Tobe locally (logged in). Output curated into `notes/asset_catalog.md` (slot-mapped, owned/free/$ tagged) + `notes/asset_buy_list.md` (Tier 0 free-on-membership grabs / Tier 1 ~$69 core / Tier 2 depth; **towers cost $0, all owned**). **Per-slot curation LOCKED** (against the real art): **tower** default = arrow box (deliberate plain starter), skins ballista/slingshot/tesla/magic-eye/crystal×3/catapult (owned; catapult needs PNG export), crystal trio = rarity line; **mob** default undead, undead reward line + recolor families (Monster Maker FREE+, monster collections, one-eyed×12) + cheap comic singles, skins must match default silhouette; **board** default summer grass, clean biomes + seasonal (owned) + novelty, **path-vs-ground contrast is the hard filter**; **FX** element families paired 1:1 to tower skins off the FREE+ "Game projectiles" kit; **flair** wood-UI frames/banners + League badges + medal emblems; **zone** = recolors (derived). **NEW DESIGN locked:** (1) **runtime-tint rule** — tier-as-color is free on outline/single-hue art (stickers, zones, simple frames) but multi-color sprites (towers/mobs) stay authored recolors; Masters = animated stroke. (2) **supply-driven reward economy** — abundant/renewable slots (mob/FX/title/zone/sticker-shape) = frequent commons, scarce (tower skins ~8) = milestones; finite tower skins are the long-term limiter (one tower milestone/season; crystal trio covers S1–S3). (3) **Season XP = tasks, not playing** → `notes/task_system.md`: five fixed shapes (build towers / build in zones / kills / games / score) × three cadences (daily ~5 / weekly ~25 / monthly ~100), Trials-or-Ranked. (4) **Ranked reward bundle** = same *type* every placement (Title + Frame + **Rank Sticker**), prestige, never on the track. (5) **Board-sticker system (new slot)** — break-the-grid chrome cosmetic: shape (uniform/season, freely chosen from earned pool) + auto rank text + tier-tinted outline (Masters animated) living in the board margin overlapping rail/edges, never over play; accretes one/season; toggle; start with zero. Docs: `design/COSMETICS.md` (rewritten with all of the above), `design/SEASON.md` (NEW — 30-tier track, supply-driven types, crystal milestones, earned-only common+rare), `notes/task_system.md` (NEW). **Open forks (NOT locked):** score-task cumulative-vs-best-run; 15-active-tasks-vs-rotating. **Drift fixed:** GTM re-logged as Steam-gated end to end (page → art read → players → Steam), not a here-doable arc. No CC blockers added; CC import notes carried (catapult PNG, board-sticker render layer).

## STATE.md — Current focus (replace the cosmetics line)

Cosmetics designed end to end (2026-06-09): catalogue + per-slot curation + season track + task
system + rank-sticker slot all locked. Build/implementation queue otherwise clear; the only
hard-gated thing is Steam identity verification → App ID + Playtest app.

## STATE.md — Recently touched files (add)

- `design/COSMETICS.md` — REWRITTEN (supply principle, runtime-tint rule, board-sticker slot, Ranked bundle)
- `design/SEASON.md` — NEW (30-tier track, supply-driven reward types, crystal milestones)
- `notes/task_system.md` — NEW (5 task shapes × 3 cadences; sole season-XP source)
- `notes/asset_catalog.md` — NEW (slot-mapped catalogue, owned/free/$ tagged)
- `notes/gds_catalog.csv` — NEW (raw 1277-pack index)
- `notes/asset_buy_list.md` — NEW (tiered acquisition list)
- `notes/tools/gds_catalog.py`, `notes/tools/gds_sheets.py` — NEW (scraper + contact-sheet builder)

## STATE.md — Open questions (add)

- Cosmetics open forks: score task (cumulative vs best run); task count (15 active vs rotating).
- Confirm the free Background Creator pack yields path tiles before relying on it for board.

---

## open_items.md — add a Resolved block + fix GTM

### Resolved 2026-06-09 (cosmetics: catalogue + curation + season/tasks + stickers)
- **Catalogue contents DONE** (was the deferred half): full store scraped → `notes/asset_catalog.md`
  + `gds_catalog.csv` + `asset_buy_list.md`; scraper/sheet tools in `notes/tools/`. Per-slot
  curation locked against real art (see STATE wrap block).
- **Season-track rewards DONE:** `design/SEASON.md` (supply-driven types, crystal milestones,
  earned-only common+rare, no prestige on track).
- **Daily-quest / season-XP source DONE** (was `season_pass.md` open): `notes/task_system.md`
  (5 shapes × 3 cadences; replaces match-completion as the XP source).
- **PVP-side reward mapping DONE** (was `season_pass.md` open): Ranked bundle = Title + Frame +
  Rank Sticker, prestige, never on track.
- **New slots:** board sticker (+ optional sticker background) added to `design/COSMETICS.md`.
- **Runtime-tint rule + supply-driven economy** locked in `design/COSMETICS.md`.

### Drift / audit — GTM (FIX)
Move GTM from "Own session (large) / here-doable" to **Steam-gated end to end**: the public page
is gated on the beta art read, which is gated on people playing the build, which is gated on
Steam. No meaningful GTM work survives upstream of the art read. (This kept resurfacing as
here-doable — it is not.)

### Open forks (cosmetics, not blocking)
- Score task: cumulative across window vs best single run.
- Active task count: all 15 (5×3) at once vs rotating subset.

### CC notes (carried, not blocking)
- Export a catapult PNG body. Import alt mobs/biomes into `src/assets/` as packs are promoted.
- Build the board-sticker render layer: chrome-edge placement, runtime outline tint per tier,
  animated multi-color stroke for Masters; toggle; never overlaps the play area.

---

## Deploy (PowerShell one-liner — run from anywhere, after hand-applying STATE/open_items edits)

```powershell
$r="C:\dev\Maze Battle TD"; $d="$HOME\Downloads"; ni "$r\notes\tools" -ItemType Directory -Force | Out-Null; mv "$d\COSMETICS.md" "$r\design\COSMETICS.md" -Force; mv "$d\SEASON.md" "$r\design\SEASON.md" -Force; mv "$d\task_system.md" "$r\notes\task_system.md" -Force; mv "$d\asset_catalog.md" "$r\notes\asset_catalog.md" -Force; mv "$d\gds_catalog.csv" "$r\notes\gds_catalog.csv" -Force; mv "$d\asset_buy_list.md" "$r\notes\asset_buy_list.md" -Force; mv "$d\gds_catalog.py" "$r\notes\tools\gds_catalog.py" -Force; mv "$d\gds_sheets.py" "$r\notes\tools\gds_sheets.py" -Force; mv "$d\wrap.md" "$r\notes\wrap.md" -Force; cd $r; git add -A; git commit -m "cosmetics: store catalogue + per-slot curation + season track + task system + rank-sticker slot; fix GTM gating drift; carry wrap.md for next-session apply"; git push
```

---

## NEXT SESSION — first task (added 2026-06-09): STATE / open_items hygiene audit

A deliberate, one-time cleanup (heavy-op: full reads of both files + sort). Goal: neither file grows.

- **STATE.md** — keep only the most recent 1-2 session-wrap blocks; move all older wrap blocks to
  `STATE_ARCHIVE.md`. STATE returns to its intended ~500-800-token cold-start size (current focus,
  next step, recently touched, open questions). This also retires the `wrap.md` workaround — once
  STATE is small, full rewrites every wrap are cheap.
- **open_items.md** — switch from accreting to **delete-on-done**. Remove resolved status churn
  outright. For any resolved block that encodes a must-not-reverse decision (locks, reversals),
  promote that one line to a "Locked decisions" list (`notes/decisions.md` or a DESIGN.md section),
  then delete the block. Result: open_items holds only OPEN items.
- **Principle going forward:** STATE = current state only (archive the log); open_items = open items
  only (delete done, promote must-keeps to the locks doc).
