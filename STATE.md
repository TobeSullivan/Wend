# State — Wend
Last updated: 2026-06-23

## Current focus
Two tracks live: (1) Steam Playtest build is **in review**; (2) the 2026-06-22 design
pivot (mobs die permanently + merge mechanic) is now **implemented in code** by CC and the
core design docs are reconciled. Remaining pivot work is balance tuning (playtest-gated)
and a few stale UI/tutorial follow-ups — see `notes/open_items.md` "Design pivot".

## Last session
- **Steam:** Playtest build uploaded via SteamPipe, depot pushed, launch option set
  (`Wend.exe`, Windows, Launch Default), build set live on a branch. **Both Store Presence
  and Game Build checklists complete and submitted for review on Jun 22** (3–5 biz days).
- **Design pivot (deliberate, post-playtest):** mobs die and stay dead; difficulty scales
  (~stage 30 cap for a normal maze); leaderboard = round + score; lives-based fail state.
  Boss every 10 rounds among the wave. Trials ~10 lives. PvP 100-life see-saw on **leaks**.
- **Merge mechanic locked:** same-tier only, pure-merge to T10 (2^n), source-empties =
  hole-in-maze risk. Multishot at 3/6/10 -> x2/x3/x4 (cap 4). Tower morphs per tier;
  barrels = shot count; body stays a skin slot. Controller = tap-to-arm; Steam Deck target.
- Built an interactive merge/juice reference for CC (`wend_merge_reference.html`).

## Next step
**Playtest the pivot and tune.** Code is in (mobs-die, lives, boss, merge ladder + juice,
per-tier morph). Open: balance the per-tier stat curves + difficulty ramp for the
~stage-30 cap, tune the lives integers, rewrite the stale tutorial beats (respawn/upgrade
anchors) and end-panel copy, and apply the §3 `test_case_library.md` edits in the
repo-cloned design session that owns that file. Detail in `notes/open_items.md`.

## Recently touched
- Steam Playtest build/launch config (Steamworks; not repo)
- notes/design_revisions_2026-06-22.md (this session)
- wend_merge_reference.html (CC reference; this session)

## Open questions / blocked on
- **21-day app-credit gate** (~mid-July) before Playtest can go Playable. Review can pass
  before then.
- Stat scaling curve deliberately deferred ("deal with that later").
- `decisions.md` + `design/DESIGN.md` now reflect the pivot (done). `test_case_library.md`
  is not in this checkout — its §3 rewrite is owed by the repo-cloned design session.
- Real capsule/key art still pending for the public Coming Soon page.
- Possible second game for Feb 2027 Next Fest — undecided.
