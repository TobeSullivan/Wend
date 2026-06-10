# SEASON — the season track (reward content layer)

Locked 2026-06-09. Builds on `notes/season_pass.md` (the soft 8wk / 30-tier framework + numbers,
unchanged as dials) and resolves its open "daily-quest" and "PVP reward mapping" items.
XP source: `notes/task_system.md`. Cosmetic model + rules: `design/COSMETICS.md`.

---

## What the track is

A **free, earned-only** cosmetic ladder. ~30 tiers, milestones at **10 / 20 / 30**. One row, no
premium track, no pricing shown (the absence of a buy button says "free" — don't label it).

- **XP is earned from tasks, not from playing.** See `notes/task_system.md`. Match-completion is
  NOT a point source (this replaces the old `season_pass.md` "complete a match: 50").
- **The track carries common + rare only.** **Prestige never appears on the track** — Ranked
  placement rewards (Title + Frame + Rank Sticker) are Ranked-exclusive (`design/COSMETICS.md`).
- Numbers (8wk, 30 tiers, the point curve in `season_pass.md`) stay as soft dials.

---

## Reward types per tier (supply-driven)

Frequency follows supply (`design/COSMETICS.md` → supply-driven reward economy). Abundant,
renewable slots carry the volume; scarce slots are the milestones.

- **Frequent commons** (most tiers): titles, zone recolors, mob recolors, FX variants, sticker
  shapes — all renewable at ~zero cost each season.
- **Uncommon** (spread between milestones): board biomes, frames, banners.
- **Milestones (10/20/30): tower skins** — the scarce hero asset. The **crystal trio is the three
  escalating milestone towers**: fire → ice → dark, across seasons 1–3.

### S1 worked layout (type per tier; the exact item is content)
1 title · 2 mob · 3 zone · 4 FX · 5 frame · 6 mob · 7 title · 8 board biome · 9 FX ·
**10 → Fire-crystal tower** (first glowy unlock — clear step up from the plain arrow box) ·
11 mob · 12 zone · 13 title · 14 FX · 15 banner · 16 mob · 17 board biome · 18 FX · 19 title ·
**20 → Ice-crystal tower + matching ice FX** (themed loadout) ·
21 mob · 22 zone · 23 frame · 24 FX · 25 title · 26 novelty biome (toy-brick / rainbow) ·
27 mob · 28 sticker shape · 29 FX · **30 → Dark-crystal tower** (season's signature top reward).

~22 of 30 tiers are mob/FX/title/zone/sticker — the renewable pools — because that's what we can
sustain season over season.

---

## Sustainability

The finite slots are the limiter: ~8 authored tower skins total → **one tower milestone per
season** (crystal trio covers S1–S3; budget new tower-art purchases for S4+). Everything abundant
renews for free, so seasons stay cheap to fill after the towers.

---

## Open forks (not locked — decide before build)

- **Score task:** cumulative across the window vs best single run. (Lean: cumulative.)
- **Active task count:** all 5 shapes at all 3 cadences at once (= 15 active) vs a rotating
  subset. (Lean: all 15; uniformity is the point.)
- Exact point values once the above settle (`season_pass.md`).
