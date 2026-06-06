# Leaderboards — design note

Rewritten 2026-06-05. Supersedes the old "with-bots / without-bots" matrix, which is
**dead**: ranked has **no bots, ever** (locked 2026-06-02), so the bot/no-bot split no
longer exists. Player-facing mode names locked 2026-06-05: **PVE = "Trials", PVP = "Ranked".**

## Backend

**Nakama handles this.** It ships leaderboards + tournaments (seasonal, auto-reset,
history-preserving) as first-class features. We are not building a ranking service — we
define board IDs, write a score on match-end, and configure season rollover as Nakama
tournaments. Self-hosted on the same box.

### Board set
- **Campaign:** 10 boards, one per mission. Metric = total damage. **All-time, not
  seasonal** (it's a tutorial; resetting it is pointless).
- **Trials (PVE):** split by `(map, window, group size)`. Combined damage isn't comparable
  across group sizes, so solo / duo / trio / quad get **separate boards**. Empty boards cost
  nothing at beta scale. Metric = total damage.
- **Ranked (PVP):** one **season rank ladder** (LP-based), not a damage board. This is "the
  season leaderboard." Full LP/MMR/tier/season spec: `notes/pvp_ladder.md`.

### Group scoring (Trials) — LOCKED 2026-06-05
Groups rank **per-team**: the group's combined score vs other groups of the same size.
Solo / duo / trio / quad are separate boards (above). Per-player was rejected — co-op is a
shared effort against a shared map with pooled lives, so per-head attribution is arbitrary
and nudges players toward hogging kills instead of building the best collective maze. It's
also less to build: one score write per match, no per-player attribution plumbing.

## Frontend — leaderboards are contextual, not a destination

Decided 2026-06-05. Leaderboards are **not** a home-screen hero (the home hierarchy is
locked: Trials/Ranked heroes, Campaign tertiary, season ambient). At most a tucked-away
tertiary entry beside Settings for browsing. Primary surfacing:

- **Trials select = the home.** That screen already shows the 5 maps + your best score and
  has daily/weekly/monthly tabs. Tap a map → its board for the selected window.
- **Post-match = the highest-value surface.** On run end: "You placed #14 this week" + the
  rows around you + "View full board." Cheap, big retention lever.
- **Ranked ladder** behind the Ranked area and, more importantly, post-match as LP delta +
  ladder position.
- **Campaign** board reachable from the mission card and post-match.

## Window cadence — RESOLVED 2026-06-05
**Keep daily / weekly / monthly, 5 maps each, as built.** The earlier recommendation to
foreground weekly/monthly over daily (on the theory a daily board barely populates before it
resets in a small pool) was overridden — the three-window structure stays as-is.

## Open
- Exact board-id schema / Nakama tournament config.
- (PVP season specifics now in `notes/pvp_ladder.md`; only inactivity decay remains, deferred.)
