# TASK SYSTEM — season XP source

Locked 2026-06-09. The sole source of season XP (see `design/SEASON.md`). Replaces the old
`season_pass.md` "complete a match" point source — **you earn XP from tasks, not from playing.**

---

## The five fixed task shapes (always the same)

All built on core mechanics, identical shapes at every cadence so they're trivial to build and
predictable to play:

1. **Build X towers**
2. **Build inside X zones**
3. **Get X kills**
4. **Play X games**
5. **Reach X score**

Progress counts in **Trials OR Ranked** — neither mode is starved, no FOMO.

---

## Three cadences (scale the threshold + the payout)

Same shapes, bigger numbers + bigger reward as the window lengthens:

- **Daily** — small (e.g. ~5-scale), small payout.
- **Weekly** — medium (e.g. ~25-scale).
- **Monthly** — large (e.g. ~100-scale).

This **caps daily gain** (healthier than rewarding raw grind) and gives a steady, legible bar
fill. The 8wk / 30-tier point budget (`season_pass.md`) is the dial these feed.

---

## Open forks

- **Score task:** cumulative across the window vs best single run. (Lean: cumulative.)
- **Active count:** all 5 shapes at all 3 cadences simultaneously (= 15 active tasks) vs a
  rotating subset to reduce clutter. (Lean: all 15 — uniformity is the whole point.)
- Exact thresholds + point values (tune with `season_pass.md`).
