# State — Wend
Last updated: 2026-06-08

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

---

## Steam (closed beta) — account status [2026-06-07]
First step toward the closed Steam beta is taken: **Steamworks partner account registered** against the existing personal Steam account (long-standing, Steam Guard on).
- **Entity type:** registered as dev/publisher — individual-vs-company choice NOT confirmed in chat. **CONFIRM** which was selected (matters for tax/bank + later restructure).
- **$100 Steam Direct fee: PAID.** → **30-day release clock is running.** Earliest possible main-game release ≈ **2026-07-07**.
- **Tax (W-9, MI) + bank (checking / USD / US): submitted.** → **Identity Verification Pending, 2–7 business days** (third-party service Lilaham/TaxIdentity). Cannot change tax/bank info or finish account creation until it clears.

**Blocked until verification clears (next actionable Steam step):**
1. Create the **Wend App ID** (the main game app).
2. Create the **Playtest app** off it — Associated Packages & DLC page → set Library capsule image + visible name ("Wend - Playtest") → walk the release-process checklist.

**Open decision to make next session (drives the Playtest config):**
- **Confidential / friends-only:** Playtest App ID + request Standard Release keys + set Playtest Playable + Store Visibility Hidden. No public page, no 2-week wait, nothing leaks. Hand keys directly to testers. *(Likely the right call for a few-friends beta.)*
- **Public Coming Soon page + Playtest signup button:** more setup, reveals Wend publicly, and the store page must be live ≥2 weeks before main-game release — but starts banking wishlists immediately.

(Steam *closed-beta mechanics* design — what the beta build actually contains/tests — remains a separate open design thread; see below.)

---

## Current focus
**Design session 4 done (2026-06-06): orchestration + Trials lobby + campaign rework specced.** Two new docs + three file edits ready for CC:
- `notes/matchmaking_orchestration.md` (NEW) — the orchestration spine. Coordinator = Nakama match handler; re-sim = async headless-Godot workers. Ranked: queue → forming lobby (fills X/8, **unanimous-of-present vote at 4–7, abstain = no, no timeout**, auto-launch at 8) → instant-join (no ready-check) → run → validate (re-sim authoritative) → settle → teardown. Speed-beats-quality matching (safe because LP is MMR-anchored). Floor = 4. Post-launch drop = forfeit. Crash = void/no-LP. Trials routes through the same spine minus elimination.
- `design/CAMPAIGN.md` (NEW) — five-mission curriculum (ramp from zero, fixing the inverted old M1), the tutorial-beat system, the ghost-outline build-guidance spec, real tutorial copy. Old 10-mission `.tres` deprecated.
- `design/DESIGN_MODES.md` (EDIT) — Trials reconciled (host launches, no ready-up gate; group size = board, no scoring vote; individual-while-grouped deferred); campaign cut to five w/ pointer to CAMPAIGN.md; PVP nav points at orchestration doc; **40×22→25×14 grid drift flagged**.
- `notes/open_items.md`, `STATE.md` (EDIT) — backlog + state updated.

**Earlier (session 3): the MP + leaderboard spine** — `notes/resim_contract.md`, `leaderboard_schema.md`, `ghost_ladder.md`, `leaderboard_ui_spec.md` + mockups. Identity: Steam auth → Nakama, one identity, display name = Steam persona.

## Next step

### ✅ §4.1 legality check (+ record serialization) — DONE 2026-06-08
The re-sim now **rejects tampered logs**, closing the second anti-cheat half (it already closed score injection; this closes *illegal* logs). All in `src/scripts/resim.gd` + the submit path, verified headless.
- **`_apply` validates every action at its tick** against the replayed authoritative state and returns a reason on failure (nothing is applied when illegal): `place` (bool of `bot_place_tower` = affordability + `_is_valid_placement`), `sell` (`_sell_tower_at_cell` false ⇒ no tower), `upgrade` (tower exists + `can_upgrade` not-maxed + `can_afford` — previously force-spent), unknown action type, bad seat. **Phase gate:** place/sell/upgrade rejected at any `phase == "run"` tick.
- **`run()` returns `legal: bool` + first-illegal `{tick, seat, action, reason}`**; the first illegal action stops the replay. **Submit path** (`scene_manager._authoritative_score`/`report_match_result`) now returns `{score, legal}` and **writes no score** when illegal.
- **Record serialization:** `Resim.encode_record`/`decode_record` (`var_to_bytes`/`bytes_to_var`; Vector2i cells; ~2.5 KB/record) — the wire/store format for the submit path.
- **Verified** (`src/tools/sim_harness.gd`, 5 checks ✅): honest round-trip (re-sim==live, dmg=54985) · serialize→deserialize identical · two tampered copies rejected (occupied cell ⇒ `illegal_place`; build action at a run tick ⇒ `phase_gate`) · inflated claim ignored · illegal log writes no score. **Note:** the check exposed that the harness had been applying *free* upgrades (direct `t.upgrade()` bypassing gold) — fixed to pay through the real economy, which dropped the honest baseline from an inflated 69962 to a legitimate 54985.

### ▶ NEXT SESSION — pick up the remaining resim_contract §10 tail + the two human items
The anti-cheat spine is now complete for solo Trials/PVE (determinism → record → re-sim → legality → authoritative write, all verified). What's left:
- **Submit path plumbing** — `encode_record` exists but nothing calls it yet; the actual Trials submit (record → bytes → server/Nakama) is a networked-MP task, sequenced with the orchestration spine.
- **Ranked placement** still reads the live coordinator (authoritative offline; networked host-side re-sim is a later MP task).
- **Wire the real server seed** into `sim_seed` (today = map.seed).

**Two items that want Tobe (not blocking code):**
- **`end`-action nod** — the "locked" §9.2 vocab was extended with an `end` bow-out marker (flagged in `resim_contract.md`). Needs an OK or a different call.
- **Human playtest** — drive a real match interactively; the tick logic is exhaustively verified headless but the live UI/fast-forward path wasn't. De-risks the whole refactor; worth doing before building more on top.

---

- **CC — sim determinism conversion: DONE ✅ (2026-06-07).** The re-sim prerequisite (§5) is built and verified:
  - **§5.1 cross-platform float test:** floats bit-identical across Win/Mac/Linux-glibc → built on `float`, no fixed-point. Probe `src/tools/float_probe.gd` + CI guard `.github/workflows/float-probe.yml`; evidence `notes/float_probe_results.md`. (Caveat: if the prod re-sim server is musl/Alpine, add a musl CI leg — glibc-only doesn't clear musl's libm.)
  - **Fixed logical tick:** all sim subsystems now stepped by one fixed-timestep clock in `match_coordinator.gd` (`SIM_DT`, `sim_tick`, accumulator + `MAX_STEPS_PER_FRAME`). Towers/spawner/projectiles/mobs no longer self-`_process` — they expose `sim_step()` and are driven in a fixed order by `BoardState.sim_step` (spawn→towers→projectiles→mobs). Clients still sim locally (entity-step on every machine; clock host-only) so netcode is preserved.
  - **Seeded RNG, ordered draws:** the crit roll (was global `randf()`) now uses one per-match `coordinator.rng`, drawn in board→placement order. Only combat roll, so "all combat rolls seeded" is satisfied.
  - **Tick-based build timer:** `build_ticks_left` is authoritative; `build_time_left` (sec) is just the HUD mirror.
  - **Verified:** `src/tools/sim_harness.gd` (headless, tick-driven) runs a full 13-round match, **byte-identical across 2 runs**, 0 errors, build-timer auto-expiry exercised. Build-phase length proven not to leak into combat outcome.
- **CC — record capture + re-sim runner: DONE ✅ (2026-06-07).** resim_contract §2/§4/§7 built and round-trip verified:
  - **Record capture:** `coordinator.{record_enabled, input_log, map_ref, ruleset_version}` + `log_input(seat, action)` (stamps `sim_tick`) + `make_record()`. Capture sites: `build_controller._place_tower`/`_sell_tower_at_cell` (via `_log_action`), `tower.upgrade`, and `request_start_now`/`set_board_ready` (start/vote_start, §9.2). map_loader wires `sim_seed = map.seed`, `map_ref`, `record_enabled = true`.
  - **Re-sim runner:** `src/scripts/resim.gd` — rebuilds the map from `map_ref`, builds a headless match (recording off), replays the tick-tagged log through the same board entry points, derives per-board score.
  - **Round-trip verified** (`sim_harness.gd`, now a capture→re-sim test): a 13-round match with 42 logged actions across rounds (incl. a round-2 placement at tick 3559) re-sims to the **exact same score** (dmg=69962, kills=485). This is the keystone property — the leaderboard number is the re-sim's, and it matches honest play.
- **CC — wire outputs: DONE ✅ (2026-06-07).** `SceneManager.report_match_result` now records the **re-sim-derived** score, never the live client tally: it re-sims `active_coordinator`'s record (set in `main.gd`) and writes that to SaveData (campaign medal / PVE best). The live tally is advisory/UX only. A mid-match bow-out logs an `end` marker so re-sim scores the partial (new `end` action — extends §9.2, flagged in `resim_contract.md` for review). **Verified** (`sim_harness.gd`): handed an inflated claim of 99,999,999, SaveData stored the honest 69,962 — "you can't write score = 9,999,999." Locally the re-sim runs client-side as the server stand-in + a determinism self-check (`push_warning` if it ever disagrees).
  - **Remaining (resim_contract §10):** solo-log **legality check** (§4.1) **DONE 2026-06-08** (see "Next step") · **record serialization** **DONE** (`Resim.encode_record`/`decode_record`); the actual **submit** wiring (record → bytes → server) is still a networked-MP task · **Ranked placement** still reads the live coordinator (authoritative for offline; networked host-side re-sim is a later MP task). Also: wire the real server seed into `sim_seed` (today = map.seed); bot upgrade-pick uses unseeded `randi()` (`bot_controller.gd:154`) — fine, bot matches are never re-simmed.
  - **Needs a human:** real interactive playtest to confirm the live (frame-accumulator) path *feels* right — tick logic is exhaustively verified but the in-app UI/fast-forward flow wasn't driven headless.
- **CC label-pass (mechanical):** Scale 1–5 → Thread/Weave/Tangle/Snarl/Knot across `design/DESIGN_MODES.md` + `design/VISUAL_SYSTEM.md`; remove the Trials "go home?" prompt. (Deliberately not done at wrap to avoid full-rewrite drift.)
- **CC — campaign rebuild: DONE ✅ (2026-06-08).** Five-mission curriculum per `design/CAMPAIGN.md`, built + headless-verified:
  - **Maps** live in `src/campaign/` (the doc's `levels/campaign/` path was wrong). `mission_01–05.tres` rewritten to ramp from zero (M1 0CP full-ghost · M2 2CP first-segment ghost · M3 3CP hint ghost · M4 1CP + 4 zones · M5 3CP + 5 zones integration). `mission_06–10.tres` deleted; `CAMPAIGN_MISSION_COUNT`/`CAMPAIGN_MISSIONS`/`campaign_select.LESSONS` trimmed to 5. Tuning + B/S/G are **gentle uncalibrated stubs** (await the 25×14 retune + playtest).
  - **Tutorial-beat schema (reopen → resolved):** an array of `TutorialBeat` sub-resources on `MapResource.tutorial_beats` (mirrors `bonus_zones`/`obstacles`; generated maps leave it empty). `TutorialBeat` = trigger/text/anchor/ghost_cells/blocking.
  - **Runtime (local board, CAMPAIGN only):** `TutorialDirector` maps match signals → 7 triggers (one-shot); `TutorialCallout` = anchored toast + blocking modal (pauses tree for M1's opener); `BuildGuide` = dashed-tile + 40%-alpha-footprint ghost outline, clears a cell on build. No new art. Callouts are positioned (no pointer-arrows yet — deferred polish).
  - **Verified** (`src/tools/campaign_verify.gd`, headless): all 5 parse, every ghost-cell set is a legal maze (path stays open), director/callout/overlay build end-to-end. **Needs a human:** M1's blocking opener (pause→"Got it"→resume) isn't auto-testable headless — confirm in playtest.
- **Design — remaining big pieces:** juice/game-feel pass · Steam closed-beta mechanics · season-pass numbers · GTM. No design piece is currently blocking CC — the orchestration + campaign specs give CC a full plate.
- Still needs two humans: a real 2-client cross-network match (targets the end-state stack).

## Recently touched files
- `src/scripts/match_coordinator.gd` — fixed-step sim clock + seeded rng + tick build timer + record capture
- `src/scripts/round_manager.gd` — `BoardState.sim_step` ordered stepping + projectiles array
- `src/scripts/{tower,spawner,projectile,mob}.gd` — `_process`→`sim_step` (externally driven); tower logs upgrades
- `src/scripts/build_controller.gd` — logs place/sell actions (`_log_action`)
- `src/scripts/map_loader.gd` — wires `sim_seed`/`map_ref`/`record_enabled` + `_map_ref_for`
- `src/scripts/resim.gd` — authoritative re-sim runner; honors `end` marker; **§4.1 legality (`_apply` validates + returns reason, phase gate, `legal`/`illegal` in `run()`) + `encode_record`/`decode_record`** (2026-06-08)
- `src/scripts/scene_manager.gd` — score write reads from re-sim; **`_authoritative_score` returns `{score, legal}` and the submit path writes no score on an illegal log** (2026-06-08)
- `src/scripts/main.gd` — sets `active_coordinator` for authoritative scoring
- `src/tools/sim_harness.gd` — determinism + round-trip + **legality/serialize/reject** regression harness; **upgrades now pay through the real economy** (2026-06-08)
- `src/tools/float_probe.gd` — NEW (§5.1 cross-platform float probe)
- `.github/workflows/float-probe.yml` — NEW (matrix CI determinism guard)
- `notes/float_probe_results.md` — NEW (float test result: floats safe ✅)
- `notes/matchmaking_orchestration.md` — NEW (orchestration spine)
- `design/CAMPAIGN.md` — NEW (five-mission rework + tutorial beats + ghost outline)
- `design/DESIGN_MODES.md` — EDIT (Trials reconciled, campaign cut to five, grid drift flagged)
- `STATE.md`, `notes/open_items.md` — updated this session

**Campaign rebuild (2026-06-08):**
- `src/resources/tutorial_beat.gd` — NEW (beat sub-resource: trigger/text/anchor/ghost_cells/blocking)
- `src/resources/map_resource.gd` — EDIT (`tutorial_beats: Array` field)
- `src/scripts/tutorial_director.gd` — NEW (signals → 7 triggers, one-shot)
- `src/scripts/tutorial_callout.gd` — NEW (anchored toast + blocking modal)
- `src/scripts/build_guide.gd` — NEW (dashed-tile + footprint ghost outline)
- `src/scripts/map_loader.gd` — EDIT (instantiates director/callout/guide for local CAMPAIGN board)
- `src/campaign/mission_01–05.tres` — REWRITTEN (five-mission ramp + beats); `mission_06–10.tres` DELETED
- `src/scripts/scene_manager.gd` — EDIT (CAMPAIGN_MISSIONS/COUNT → 5)
- `src/scripts/campaign_select.gd` — EDIT (LESSONS → 5, grid is now one row)
- `src/tools/campaign_verify.{gd,tscn}` — NEW (headless resource+maze+director verifier)

## Open questions / blocked on
Full per-item status in `notes/open_items.md`. Active design: juice/game-feel pass · season-pass numbers · Steam closed-beta mechanics · GTM. CC chores: determinism (first job) · scale-name label-pass · campaign rebuild. Config-level: leaderboard reset anchors (proposed UTC), season length; queue escalation timings + join-window (dials, need telemetry). Blocked on data: B/S/G calibration, PVP seed-convergence, economy re-tune + campaign tuning integers for 25×14. Parked: individual-while-grouped Trials scoring, Ranked ready-check, crash match-reconstruction.

**Steam (ops):** identity verification pending (2–7 biz days, started 2026-06-07) — blocks App ID + Playtest creation. Confirm entity type chosen at registration. Decide confidential-keys vs. public-Coming-Soon for the Playtest.
