# State

Last updated: 2026-05-30

---

## Current focus

**Mode design and map resource architecture locked.** This session defined all three game modes (Campaign, PVE, PVP) in full, the season/progression system, the map resource schema, and the GameConstants/MapResource split architecture. Design artifacts produced: `DESIGN.md` (updated — core gameplay only) and `DESIGN_MODES.md` (new — modes, maps, progression, seasons, resource architecture).

**Next build focus: mission/map resource framework in Godot.** Implement `MapResource`, `ZoneDefinition`, `GameConstants` autoload, `map_generator.gd`, and `map_loader.gd`. Refactor `main.gd` to consume a `MapResource` instead of hardcoded values. Author `mission_01.tres` as the first campaign mission to validate the authoring workflow.

---

## Mode design session — 2026-05-30

Full mode design locked this session. Key decisions:

### Campaign
- Solo only, 10 missions max, static hand-authored maps
- Tutorial function only — not the product's selling point
- Bronze/Silver/Gold thresholds feed season pass milestones; Gold should be easily attainable
- Per-mission leaderboard (total damage)

### PVE (Leaderboard mode)
- 1–4 players, invite-only, no random matchmaking
- 5 curated seeded maps per daily/weekly/monthly window
- Scale 1–5: supply 10→50, checkpoints 1→3, zones 1–2→5–6, mob count ~8→~24, rounds 10–13→26–30
- Round count seeded-random within scale range; same for all players on that map that window
- Only completed runs post scores; best score per player per map counts
- Leaderboards: Daily/Weekly/Monthly × Solo/Duo/Trio/Quad
- Team vs individual score: per-match vote, squad default, host breaks ties
- Individual score in a friend lobby posts to Solo leaderboard
- No bots in PVE
- Arena: 2-column grid, filled slots only, hidden build phase, visible run phase

### PVP (Ranked)
- 8 players, solo queue only, no group queue ever
- Fully randomized seeded maps per match
- 100 lives per player, 800 total pool, zero-sum
- Model B pairwise kill transfers per round, full strength from round 1
- Elimination at 0 lives; eliminated player's lives leave the pool
- Placement = elimination order; LP-per-placement ranking
- Rank tiers: Bronze → Silver → Gold → Platinum → Masters
- Season soft reset: one tier drop at season end
- Masters cosmetic includes final numeric rank (e.g. "162nd Masters Season 1"), permanent

### Seasons
- Same reset cadence for PVE and PVP
- PVP: tier at season end determines reward
- PVE: battle pass milestone chain, no premium tier, free rewards for all
- Season pass points from: playing matches, hitting milestones, posting to leaderboards
- All rewards cosmetic only: tower skins, projectile skins, profile flair, season board
- Season boards displayed in lobbies — prestige legible at a glance
- History preserved indefinitely

### Map resource architecture
- Single `MapResource` format serves all three modes
- Campaign: hand-authored `.tres` files in `src/campaign/`
- PVE/PVP: `MapResource` objects generated in memory by `map_generator.gd`
- `map_loader.gd` configures the scene from the resource; `main.gd` agnostic to mode
- `GameConstants` autoload singleton for all global constants
- Per-map variables (supply, rounds, mob count, thresholds, layout) in `MapResource`
- Threshold derivation formula: `total_base = base_dps × supply_cap × round_count`; bronze ×0.6, silver ×1.0, gold ×1.5

---

## Playtest tweak pass + crash fix + UX — 2026-05-30

See previous STATE entry (preserved below in git history). Summary: fast-forward, off-screen entry/exit, death FX, obstacles, per-tower damage/kill tracking, effective-stat readouts, round-end gold toast, win-on-Gold modal, crash fix on placement path cache.

---

## Next step

**For Claude Code:**

1. Create `src/resources/game_constants.gd` — autoload singleton, move all magic numbers from existing scripts into it
2. Create `src/resources/map_resource.gd` — MapResource schema (extends Resource)
3. Create `src/resources/zone_definition.gd` — ZoneDefinition sub-resource
4. Create `src/scripts/map_loader.gd` — reads MapResource, configures scene
5. Refactor `main.gd` — remove all hardcoded map config, consume MapResource via map_loader
6. Create `src/campaign/mission_01.tres` — first campaign mission, hand-authored, validates the workflow
7. Create `src/scripts/map_generator.gd` stub — takes seed + scale tier, returns MapResource (full procgen algorithm TBD, stub sufficient to unblock campaign work)

Do these in order. Each step unblocks the next. After step 6, the campaign authoring workflow is validated and mission 02–10 can be authored incrementally.

**For this Claude (design):**

- Leaderboard backend design (captured in `notes/leaderboards.md` — needs updating with mode decisions from this session)
- Pause menu spec (previously parked)
- Specialization milestone effects (still open)
- Home screen / level-select UX

---

## Recently touched files

- `DESIGN.md` — updated (modes section replaced with pointer to DESIGN_MODES.md; core gameplay content preserved and cleaned)
- `DESIGN_MODES.md` — new file
- `STATE.md` — this file

---

## Open questions / blocked on

### Implementation (Claude Code)
- Procgen algorithm for PVE/PVP map generation — constraints are specced in DESIGN_MODES.md, algorithm is implementation TBD
- Bot behavior in PVP private lobbies — damage curve vs actual maze-building (deferred, not needed for campaign or ranked)
- Eliminated player maze handling in PVP — freeze in place, vanish, or ghost visible (deferred)
- Networking/hosting model (deferred)

### Design (this Claude)
- Specialization milestone effects — what does each specialization actually do?
- Soft caps for damage / range / attack_speed upgrade stats
- Damage threshold calibration — current prototype values (1250/1875/2500) are placeholders; real tuning needs playtest data
- Home screen / level-select UX
- Pause menu full spec
- Leaderboard backend design (notes/leaderboards.md needs update for new mode decisions)
- PVP LP curve (exact points per placement TBD)
- Season pass point values and milestone thresholds

### Locked design decisions
See `DESIGN.md` and `DESIGN_MODES.md`. Decisions there are not re-litigated without explicit reopening.
