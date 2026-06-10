# Season pass — design note

Captured 2026-06-05. Locked numbers 2026-06-10.

## Locked
- Free pass. **Cosmetic only, no power.** No premium tier, no microtransactions.
- Progress via a milestone/point chain (battle-pass structure).
- Cosmetic-pass tiers are **independent** of the 1/2/3-star damage thresholds.
  Star thresholds can feed points, but the pass tiers are point-count gates. Don't entangle.
- **8-week season, 30 tiers, 1,000 pts/tier = 30,000 pts to finish.**
- **XP comes from tasks only** (see `notes/task_system.md`). "Complete a match: 50" is dead.

## Point sources

### Tasks (sole XP source)
Payout chain: **×5 daily→weekly, ×4 weekly→monthly** (governing both thresholds and payouts).

| Cadence | Per task | All 5 tasks | Over the season |
|---|---|---|---|
| Daily | 120 | 600/day | 33,600 (56 days) |
| Weekly (×5) | 600 | 3,000/wk | 24,000 (8 wks) |
| Monthly (×20) | 2,400 | 12,000/window | 24,000 (2 windows) |

Ceiling (everything): ~81,600 pts against a 30,000 track → **~37% capture to finish.**
Engaged player (~30 min/day) finishes around week 6. Twice-a-week casual lands ~70%.
Daily cap (600) is the grind guard — binge sessions don't front-load the track.

### Trials placement bonus (only skill-based income)
Top 100 / top 10 / #1 at window close: **100 / 250 / 500 pts.** A rounding bonus, not a driver.
Rewards showing up; doesn't gate cosmetics behind being good.

### Absolute thresholds (the X in "Get X kills")
Playtest-gated, same as star-threshold calibration. Tune after real data.

## Rewards
See `design/SEASON.md` for the full tier map. Milestone towers at 10/20/30.
Profile flair + board sticker shape on the track; Ranked prestige (Title + Frame + Rank Sticker)
is Ranked-exclusive and never on the track.

## Open
- Absolute task thresholds (playtest-gated).
