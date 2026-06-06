# State — Wend
Last updated: 2026-06-06

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
**Design session 3 done (2026-06-06): the multiplayer + leaderboard spine is fully specced.** Five new/updated design docs ready for CC:
- `notes/resim_contract.md` (NEW) — authoritative scoring: server replays seed + input log → true score. Source of truth for Trials scores AND Ranked placement. Determinism is the hard prerequisite.
- `notes/leaderboard_schema.md` (REWRITTEN) — board-id schema; **Trials boards ephemeral (purge on reset)**; **Ranked = one global tiered ladder per season** (tiers are bands, not separate boards).
- `notes/ghost_ladder.md` (NEW) — in-match "next score to beat": snapshot-at-start ghost model, 4 target states, never asserts live rank; live rank only on result screen. Removes the Trials "go home?" prompt.
- `notes/leaderboard_ui_spec.md` (NEW) — the 4 UI surfaces, built from the mockups.
- `notes/mockups/leaderboard_surfaces_mockup.html`, `leaderboard_ui_pass2.html`, `ranked_ladder_bands.html` (NEW) — the reviewed previews.

**Identity ratified:** Steam auth → Nakama; one identity; display name = Steam persona.

## Next step
- **CC — first job: make the sim deterministic** (the re-sim prerequisite). Fixed logical tick (towers/spawner/projectiles are on `_process(delta)` today — framerate-dependent); one seeded RNG with ordered draws (crit uses global `randf()` today); tick-based build timer. **TEST CROSS-PLATFORM FLOAT FIRST** (Win/Mac client vs Linux server) per `resim_contract.md` §5.1 — cheapest possible test, decides whether floats are OK or we go fixed-point. Pays off twice (anti-cheat AND clean lockstep MP).
- **CC label-pass (mechanical):** Scale 1–5 → Thread/Weave/Tangle/Snarl/Knot across `design/DESIGN_MODES.md` + `design/VISUAL_SYSTEM.md`; remove the Trials "go home?" prompt. (Deliberately not done at wrap to avoid full-rewrite drift — same pattern as the Trials/Ranked rename.)
- **Design — next big piece (its own session): matchmaking + orchestration model** — press-queue → form 8 → assign/spawn headless match instance → lifecycle. The other half of "real MP" alongside re-sim. Needs a read of `notes/multiplayer_architecture.md` + `server_decision.md` to build on what's there.
- **Then:** Steam closed-beta mechanics (app id $100, Playtest vs beta branch, Win+Mac export presets) · juice pass · onboarding (minimal for closed beta) · season-pass numbers · GTM.
- Still needs two humans: a real 2-client cross-network match (now targets the end-state stack, not Option A).

## Recently touched files
- `notes/resim_contract.md` — NEW (authoritative scoring contract)
- `notes/leaderboard_schema.md` — REWRITTEN (ephemeral Trials, global tiered Ranked ladder)
- `notes/ghost_ladder.md` — NEW (in-match target display)
- `notes/leaderboard_ui_spec.md` — NEW (4 surfaces)
- `notes/mockups/leaderboard_surfaces_mockup.html`, `leaderboard_ui_pass2.html`, `ranked_ladder_bands.html` — NEW
- `STATE.md`, `notes/open_items.md` — updated this session

## Open questions / blocked on
Full per-item status in `notes/open_items.md`. Active: matchmaking/orchestration (next design session) · Trials group-lobby flow (scoring locked, flow undesigned) · onboarding · season-pass numbers · Steam closed-beta mechanics · the DESIGN_MODES/VISUAL_SYSTEM scale-name label-pass (CC chore). Config-level: leaderboard reset anchors (proposed UTC), season length. Blocked on data: B/S/G threshold calibration, PVP seed-convergence, economy re-tune for the bigger board.
