# Leaderboards — design note (to be planned in a dedicated session)

Captured 2026-05-30. This is a parked decision, not yet implemented.

## Requirement

We want **separate leaderboards per lobby format**, and within each grouped
format, **split by whether bots were allowed**:

| Format | With bots | Without bots |
|--------|:---------:|:------------:|
| Solo (1) | ✅ board | ✅ board |
| Duo (2)  | ✅ board | ✅ board |
| Trio (3) | ✅ board | ✅ board |
| Quad (4) | ✅ board | ✅ board |
| Full lobby (8) | — | ✅ board (all humans, **no groups**, **no bots**) |

That's **9 leaderboards total**: 4 grouped formats × {with-bots, without-bots} = 8,
plus the single all-8 humans-only board.

### Key points
- The all-8 board is humans-only by definition — no bot variant, and "no groups"
  (it's the pure free-for-all ranked format).
- "With bots" vs "without bots" must be tracked per match so scores route to the
  correct board.
- Solo here means single-player ranked score (total damage). The grouped formats
  (Duo/Trio/Quad) imply team/party play — scoring model for groups still TBD.

## Open questions to resolve when planning
- What score metric ranks each board? (SP = total damage. Group formats = ?)
- For grouped formats, is the leaderboard per-player or per-team?
- Does bot difficulty factor into "with bots" boards, or is any-bot enough to
  segregate?
- Seasonality / resets?
- How this interacts with the DESIGN ranked vs private lobby split (ranked = always
  8, no invites; private = 1–8 with optional bots).

> Plan this in its own chat before building.
