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
- **Verified:** clean headless import (no parse/shadow); `sim_harness` round-trip bit-identical with
  merges, tampered logs rejected, WIRING confirms the composite is stored authoritatively; `match_shot`
  runtime clean.

## Next step
- **Playtest the new scaling at real maze density** — confirm early waves pressure without being
  impossible and the ~R30 normal-maze cap holds; tune `WAVE_COUNT_*` / `MOB_*` as needed. Same pass
  validates the `TRIALS_STAR_ROUNDS [10,20,30]` star cutoffs.
- Carry-over: playtest the tier aura; rewrite stale tutorial copy; `test_case_library.md` edits owed by
  the repo-cloned design session.

## Recently touched
- src/resources/game_constants.gd, src/scripts/{match_coordinator,round_manager,build_controller,
  scene_manager,leaderboard_service,leaderboard_browse,match_end_panel,rail}.gd, src/tools/sim_harness.gd
- deploy/nakama/data/modules/index.js (score-truncation fix; deployed)
- STATE.md, notes/open_items.md

## Open questions / blocked on
- **Steam:** review pending (can pass before the **21-day app-credit gate**, ~mid-July, that blocks
  Playtest going Playable). When verification clears: create App ID → confidential Playtest app.
- Per-tier stat curves + lives integers still deferred to playtest (wave scaling now landed).
- `test_case_library.md` not in CC's checkout — its §3 rewrite + the new aura case are owed by the
  repo-cloned design session.
- Real capsule/key art still pending for the public Coming Soon page.
- Possible second game for Feb 2027 Next Fest — undecided.
