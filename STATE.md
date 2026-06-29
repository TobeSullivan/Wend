# State — Wend
Last updated: 2026-06-28

## Current focus
(1) Steam Playtest build is **in review** (submitted Jun 22); (2) the 2026-06-22 pivot + tier aura
are implemented; (3) **this session (CC):** balance + endless-leaderboard pass — wave scaling, the
round-based (rounds-primary / score-tiebreak) Trials leaderboard, and one-and-done tower placement.
Nakama beta module **deployed** with the score-truncation fix.

## Last session
- **Scaling.** Waves now grow with the round (`WAVE_COUNT_BASE 14 +2/round, cap 60`); mobs tankier
  (`MOB_BASE_HP 150`, HP ramp starts R4); denser spawns (`SPAWN_INTERVAL 0.8`). Wave size was
  previously **fixed at 8 forever** — `mob_count_for_round()` in `match_coordinator` scales it for
  endless/PvP (campaign keeps authored counts), threaded through `start_run`. Resim-safe (pure fn of
  round+mode). All values playtest-tunable.
- **Leaderboard → round-based.** Trials ranks **rounds-reached (primary) + score (tiebreak)** via a
  composite `rounds*1e12 + score`, computed from the authoritative re-sim (`final_round` + damage) so
  it stays anti-cheat-safe and needs **no Nakama sort change** (single desc int). End screen now reads
  **"You reached Round N — Score: Y"**; placement/browse rows show `R# · score`; rail shows best round;
  Trials star medals retired (campaign keeps its medals). Decode helpers in `LeaderboardService`.
- **Nakama module fix (REQUIRED + deployed).** `submit_score` did `req.score | 0` → 32-bit truncation
  (~2.1B), which mangled the ~1.2e13 composite. Changed to `Math.floor(Number(...))`. Deployed to the
  box (`trials_beta_*` boards are new → no wipe needed). Also fixes latent >2.1B raw-damage truncation.
- **Building.** Placing a tower now exits build mode; **hold Shift** to chain placements (merge made
  rapid multi-place feel wrong). Touch tap-to-confirm unaffected.
- **Star rating (1/2/3 stars).** Renamed `bronze/silver/gold` → `star1/2/3` across code + `.tres` +
  docs (`medal_for` → `star_rating(value)→int`, `gold_goal_reached` → `top_star_reached`). Trials
  stars are now **round milestones** (`TRIALS_STAR_ROUNDS [10,20,30]` — reach round N); campaign keeps
  authored damage thresholds. `star_metric()` returns rounds (endless) / damage (campaign). Ranked
  Stone→Masters bands untouched. Old string saves read via a compat shim.
- **Per-tier difficulty + logging.** `SCALE_HP_MULT [0.45,0.70,1.0,1.45,1.9]` by scale_tier, ramped in
  over `SCALE_HP_RAMP_ROUND 18` (early near-parity, full spread by ~R18) so ~R30 is the soft wall on
  every scale; Trials/PvP only (campaign untouched), coordinator reads `scale_tier`, resim-safe. Removed
  the late-round build-timer drop (`BUILD_TIME_LATE`/`LATE_ROUND_THRESHOLD`) — all rounds now 25s.
  `PlaytestLog.ENABLED = true` (writes `user://playtest_log.jsonl`). **Starting values — fit to logs.**
- **QoL.** Build a T1 on a T1 to merge instantly (`build_merge` action — full record/resim/net plumbing,
  round-trip verified). Path indicator is now a **marching dashed line** (road_renderer `_DashLayer`),
  replacing the hard-to-follow `>` chevrons. Pressing **B at supply cap is now a no-op**.
- **Two bug fixes.** Projectiles fired on a round's final tick no longer linger (cleared in
  `settle_round`). Merge "gap!" text is white+outline (was illegible gold).
- **Monitoring (catch a future leak).** `DebugOverlay` autoload — F3 live overlay (FPS/nodes/orphans/
  objects/mem with peaks) + a `[MONITOR]` line to the log every 30s. External `mem_watchdog.ps1` on the
  Desktop. WER LocalDumps **pending one elevated command** (HKLM) to capture crash minidumps.
- **Memory-crash diagnosis (NOT Wend).** PC-log forensics: the recurring crash is **ClassicUO** (Ultima
  Online / Tides of Power), `0xC0000005` access violation, 4+ times, heap-corruption signature. Wend's
  build/teardown probe was clean (0 orphans, flat counts). Report on Desktop for the UO devs.
- **Verified:** clean headless import (no parse/shadow); `sim_harness` round-trip bit-identical with
  merges **and a build_merge**, tampered logs rejected, WIRING confirms the composite stored.

## Next step
- **Playtest each scale at least once, then fit the curves from `playtest_log.jsonl`** — user is doing
  one run per scale before a balance pass. Fit `SCALE_HP_MULT` so ~R30 is the casual wall on every
  scale, then set per-scale (or uniform) `TRIALS_STAR_ROUNDS` so gold lands well before 30.
- Run the elevated WER-LocalDumps command so any future Godot/ClassicUO crash drops a minidump.
- Carry-over: playtest the tier aura; rewrite stale tutorial copy; `test_case_library.md` edits owed by
  the repo-cloned design session.

## Recently touched
- src/scripts/debug_overlay.gd (new, autoload), road_renderer.gd (dashed path), build_controller.gd
  (build_merge + B-at-cap), match_coordinator/game_constants (per-tier HP, timer), round_manager/merge_fx
  (bug fixes), resim/net_protocol/net_match (build_merge plumbing), playtest_log (enabled), project.godot
- Desktop (not in repo): ClassicUO_crash_report.txt, mem_watchdog.ps1
- STATE.md

## Open questions / blocked on
- **Steam:** review pending (can pass before the **21-day app-credit gate**, ~mid-July, that blocks
  Playtest going Playable). When verification clears: create App ID → confidential Playtest app.
- Per-tier stat curves + lives integers still deferred to playtest (wave scaling now landed).
- `test_case_library.md` not in CC's checkout — its §3 rewrite + the new aura case are owed by the
  repo-cloned design session.
- Real capsule/key art still pending for the public Coming Soon page.
- Possible second game for Feb 2027 Next Fest — undecided.
