# State — Wend
Last updated: 2026-06-07

> **Read order:** `claude-rules.md` → `RULES.md` → this file → `notes/open_items.md` (full backlog) → only the specific file the task needs.
> **History:** older session logs were moved to `STATE_ARCHIVE.md` — reference only, don't load unless you're digging into a past decision.

---

## ⚠️ Recent reversals — do NOT act on stale instructions
- **Platform: PC/Mac-first. Mobile NEVER** (console if it succeeds; mobile only on viral success). Mobile would be a *fork*, not a port.
- **Board is 25×14** (locked + implemented). The old 20×11 mobile shrink is dead.
- **In-match UI = the 2026-06-05/06 v3 bounded layout** (recessed surround + bright bordered board, right inspector dock, redesigned victory panel).
- **Pricing: $10–15 (PC band).** Saves = Steam Cloud.
- **No disposable intermediates (NEW 2026-06-06).** We build toward the end state, not throwaway rungs. itch.io beta is DEAD → **closed Steam beta** is the target. Re-sim/anti-cheat and real queue-based multiplayer (Option B) are **pulled forward**, not deferred. See `notes/open_items.md` "session 3".

---

## Name
**"Wend"** (locked). Subtitle carries genre. **Modes: Trials (PVE), Ranked (PVP).**
**Trials scale names: Thread · Weave · Tangle · Snarl · Knot** (1→5, locked 2026-06-06).

## Current focus
**Design session 4 done (2026-06-06): orchestration + Trials lobby + campaign rework specced.** Two new docs + three file edits ready for CC:
- `notes/matchmaking_orchestration.md` (NEW) — the orchestration spine. Coordinator = Nakama match handler; re-sim = async headless-Godot workers. Ranked: queue → forming lobby (fills X/8, **unanimous-of-present vote at 4–7, abstain = no, no timeout**, auto-launch at 8) → instant-join (no ready-check) → run → validate (re-sim authoritative) → settle → teardown. Speed-beats-quality matching (safe because LP is MMR-anchored). Floor = 4. Post-launch drop = forfeit. Crash = void/no-LP. Trials routes through the same spine minus elimination.
- `design/CAMPAIGN.md` (NEW) — five-mission curriculum (ramp from zero, fixing the inverted old M1), the tutorial-beat system, the ghost-outline build-guidance spec, real tutorial copy. Old 10-mission `.tres` deprecated.
- `design/DESIGN_MODES.md` (EDIT) — Trials reconciled (host launches, no ready-up gate; group size = board, no scoring vote; individual-while-grouped deferred); campaign cut to five w/ pointer to CAMPAIGN.md; PVP nav points at orchestration doc; **40×22→25×14 grid drift flagged**.
- `notes/open_items.md`, `STATE.md` (EDIT) — backlog + state updated.

**Earlier (session 3): the MP + leaderboard spine** — `notes/resim_contract.md`, `leaderboard_schema.md`, `ghost_ladder.md`, `leaderboard_ui_spec.md` + mockups. Identity: Steam auth → Nakama, one identity, display name = Steam persona.

## Next step
- **CC — make the sim deterministic** (the re-sim prerequisite). **§5.1 cross-platform float test: DONE ✅ (2026-06-07) — floats are bit-identical across Win/Mac/Linux-glibc, so we build the conversion on `float`, no fixed-point.** Probe `src/tools/float_probe.gd` + CI guard `.github/workflows/float-probe.yml` (stays as the regression test); evidence in `notes/float_probe_results.md`. **Remaining conversion work:** fixed logical tick (towers/spawner/projectiles are on `_process(delta)` today — framerate-dependent); one seeded RNG with ordered draws (crit uses global `randf()` at `tower.gd:175` today); tick-based build timer (currently wall-clock `delta` in `match_coordinator.gd:88`). This structural work is platform-neutral and pays off twice (anti-cheat AND clean lockstep MP). (Caveat: if the prod re-sim server ends up musl/Alpine, add a musl CI leg before trusting cross-platform — glibc-only doesn't clear musl's libm.)
- **CC label-pass (mechanical):** Scale 1–5 → Thread/Weave/Tangle/Snarl/Knot across `design/DESIGN_MODES.md` + `design/VISUAL_SYSTEM.md`; remove the Trials "go home?" prompt. (Deliberately not done at wrap to avoid full-rewrite drift.)
- **CC — campaign rebuild:** five missions per `design/CAMPAIGN.md`; deprecate old `levels/campaign/` `.tres`; build the tutorial-beat system (schema reopen, runtime shape CC's call) + ghost-outline overlay.
- **Design — remaining big pieces:** juice/game-feel pass · Steam closed-beta mechanics · season-pass numbers · GTM. No design piece is currently blocking CC — the orchestration + campaign specs give CC a full plate.
- Still needs two humans: a real 2-client cross-network match (targets the end-state stack).

## Recently touched files
- `src/tools/float_probe.gd` — NEW (§5.1 cross-platform float probe)
- `.github/workflows/float-probe.yml` — NEW (matrix CI determinism guard)
- `notes/float_probe_results.md` — NEW (float test result: floats safe ✅)
- `notes/matchmaking_orchestration.md` — NEW (orchestration spine)
- `design/CAMPAIGN.md` — NEW (five-mission rework + tutorial beats + ghost outline)
- `design/DESIGN_MODES.md` — EDIT (Trials reconciled, campaign cut to five, grid drift flagged)
- `STATE.md`, `notes/open_items.md` — updated this session

## Open questions / blocked on
Full per-item status in `notes/open_items.md`. Active design: juice/game-feel pass · season-pass numbers · Steam closed-beta mechanics · GTM. CC chores: determinism (first job) · scale-name label-pass · campaign rebuild. Config-level: leaderboard reset anchors (proposed UTC), season length; queue escalation timings + join-window (dials, need telemetry). Blocked on data: B/S/G calibration, PVP seed-convergence, economy re-tune + campaign tuning integers for 25×14. Parked: individual-while-grouped Trials scoring, Ranked ready-check, crash match-reconstruction.
