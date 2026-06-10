# TASK SYSTEM — season XP source

Locked 2026-06-09. Forks closed 2026-06-10.
The sole source of season XP (see `design/SEASON.md`). Replaces the old
`season_pass.md` "complete a match" point source — **you earn XP from tasks, not from playing.**

---

## The five fixed task shapes (always the same)

All built on core mechanics, identical shapes at every cadence so they're trivial to build and
predictable to play:

1. **Build X towers**
2. **Build inside X zones**
3. **Get X kills**
4. **Play X games**
5. **Reach X score** — cumulative across the window (not best single run)

Progress counts in **Trials OR Ranked** — neither mode is starved, no FOMO.

---

## Three cadences (scale the threshold + the payout)

All 15 tasks (5 shapes × 3 cadences) are active simultaneously. Uniformity is the point —
no rotating subset, no clutter question.

Payout chain: **×5 daily→weekly, ×4 weekly→monthly.**

| Cadence | Payout per task | All 5 | Over season |
|---|---|---|---|
| Daily | 120 | 600/day | 33,600 |
| Weekly | 600 | 3,000/wk | 24,000 |
| Monthly | 2,400 | 12,000/window | 24,000 |

This **caps daily gain** (healthier than rewarding raw grind) and gives a steady, legible bar
fill. Full economy in `notes/season_pass.md`.

---

## Runtime
Built 2026-06-10 (`src/scripts/task_catalog.gd` = `TaskCatalog`). Schema + pure roll/accumulate/
award logic live there; `SaveData.tasks()` holds the raw blob (catalog-agnostic). Window keys reuse
`LeaderboardService.window_date` so resets land on the Trials daily/weekly/monthly boundaries.
`SceneManager._record_match_tasks()` feeds it at the Trials + Ranked match-end paths only (campaign +
casual excluded); stats read client-side off the local board, never into the match record. Points flow
to `SaveData.add_season_points()` → the track. Verified by `src/tools/task_catalog_test.tscn` (green).

## Open
- Absolute thresholds (the X integers) — playtest-gated, tune with star thresholds. Stand-ins live in
  `TaskCatalog.THRESHOLDS`; structure + payouts are locked, only the integers move.
