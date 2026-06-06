# Open items — backlog ledger

Living backlog. STATE.md's "Open questions" points here; this is the full picture so STATE
itself stays small.

Status key: **RESOLVED** · **NEAR** · **REC-PENDING** · **DIRECTION-SET** · **UNTOUCHED** ·
**BLOCKED-DATA** · **OWN-SESSION**

---

## Resolved 2026-06-06 (session 3 — MP + leaderboard spine)
- **MINDSET: no disposable intermediates.** Build toward the end state, not throwaway rungs we replace next session. The reason staged bring-up exists is *failure isolation* (a CC/debug concern), NOT a reason to design/lock disposable architectures. Consequence: **itch.io beta is DEAD → closed Steam beta is the target**; re-sim/anti-cheat and real queue-based multiplayer (Option B) are **pulled forward**, not deferred. Dedicated server already live is the one validated piece we keep.
- **Re-sim / authoritative scoring → LOCKED.** `notes/resim_contract.md`. Server replays seed + ordered input log → derives true score; client scores advisory only. Source of truth for Trials scores AND Ranked placement. Cheaper than live-authoritative (send a recipe, not a video; bill scales with players, not this choice). Closes score-injection, not botting (stated boundary). Disconnect/reconnect model locked: board keeps playing as left (empty input continuation), "disconnected" badge, eliminated-if-dies-before-return; server-observed timeline, zero advantage to quitting. Ruleset versioning → **grandfather + reset on balance patch** (campaign all-time exempt). Action vocab locked (place/sell/upgrade + start-round: per-round build timer in TICKS, early-start via solo button or MP unanimous `vote_start`, authoritative start = min(timer, last-yes), derivable from log). Map version tags yes.
- **Determinism = CC's FIRST job** (re-sim prerequisite). Sim is NOT deterministic today: towers/spawner/projectiles on `_process(delta)` (framerate-dependent), crit uses global `randf()` (unseeded). Map generation already deterministic from seed (head start). Fix: fixed tick + seeded ordered RNG + tick-based timer. **Cross-platform float test FIRST** (Win/Mac vs Linux server) → floats-OK or fixed-point. Pays off twice (anti-cheat + lockstep MP).
- **Identity → Steam auth → Nakama** (ratified). One identity across modes; display name = Steam persona; no custom account system.
- **Leaderboard board-id schema → LOCKED.** `notes/leaderboard_schema.md`. Campaign = 10 all-time leaderboards. Trials = 60 tournaments `trials_<window>_<scale>_<group>`, **EPHEMERAL (purge on reset — no historical browsing; flat constant storage)**. Ranked = **one global tiered ladder per season** `ranked_s<N>`: all players ranked 1→N, tiers are bands (value = tier_base+LP), current live + past frozen top-N + per-player record + no future. Reset anchors proposed UTC.
- **In-match ghost ladder → LOCKED.** `notes/ghost_ladder.md`. Merges named tiers + leaderboard into one ascending target ladder. Snapshot-at-match-start (shared per board = one cached fan-out; stable rungs). 4 states: named tier → ghost score → own best (empty-board fallback) → TOP. **Never asserts live rank in-match**; live rank only on result screen (Trials rank / Ranked placement + LP + global-rank delta). **Removes the Trials "go home?" prompt** (campaign-ism).
- **Leaderboard UI surfaces → LOCKED.** `notes/leaderboard_ui_spec.md` + 3 mockups in `notes/mockups/`. (1) Trials post-match placement in victory panel; (2) Ranked post-match placement; (3) board-browse (Trials ephemeral + countdown; Ranked global tiered ladder; Campaign); (4) Trials-select cards with inline live rank as tap target.
- **Trials scale names → Thread / Weave / Tangle / Snarl / Knot** (1→5). "Scale N" was placeholder. Ties to the game name (threading a maze). NOTE: labyrinth ≠ harder than maze (it's unicursal/simpler) — names chosen for gradient feel, not technical accuracy. **CC label-pass needed** across `DESIGN_MODES.md` + `VISUAL_SYSTEM.md` (mechanical find-replace; not done at wrap to avoid full-rewrite drift).

## Resolved 2026-06-05 (session 2 — design wrap)
- **Game NAME → "Wend"** (Steam-clear). Genre lives in a subtitle/tagline. Unblocks the Steam page.
- **PVE/PVP player-facing names → "Trials" / "Ranked".** Home hierarchy unchanged.
- **PVE window cadence → keep daily/weekly/monthly (5 maps each).**
- **Vertical slice → the beta/demo plays that role**, not a formal slice.
- **Leaderboard group scoring → per-team, separate boards by size** (solo/duo/trio/quad).
- **PVP LP curve + season specifics → designed.** `notes/pvp_ladder.md` (MMR-anchored net-positive). Numbers are playtest dials; shape locked. Only inactivity decay deferred.
- **Soft caps → governed-by-economy, no change.** Revisit trigger (CC-side, live log): more starting gold, longer runs, higher supply, or board rescale changing gold output.
- **Accessibility / zones → label + color + uniform shape, icons where verified.** speed→fast_forward, slow→waiting, damage→energy; range label-only (no glyph in pack).

## Resolved 2026-06-05 (session 1)
- **Platform fork** → PC/Mac-first; mobile never; console if successful. LOCKED.
- **Pricing band** → $10–15 PC. One-time premium, no microtransactions.
- **Progression persistence** → Steam Cloud (Nakama holds MP/leaderboard profiles).
- **Leaderboard backend** → Nakama. **Frontend** → contextual.
- **In-match UI layout** → approved (recessed surround + bounded arena, flex, right dock).
- **Victory screen** → redesigned.
- **Steelman A** (PVE is the spine, PVP optional) → accepted.
- **Steelman B** (single-tower mazing is a PILLAR) → LOCKED, not re-litigated.
- **Ranked PVP is a real shipping ambition** → confirmed; anti-cheat + queue population on the launch critical path.

## Resolved 2026-06-06 (board/UI build)
- **Board final tile count → 25×14. LOCKED + IMPLEMENTED.**
- **In-match UI rebuild → DONE (v3 bounded layout).** Victory screen redesigned.
- **Soft-caps revisit trigger note:** board-rescale lever fired; economy/supply re-tune still deferred (BLOCKED-DATA) — CC checks live log before any cost bend.

## Direction set — system still undesigned
- **Anti-cheat** — **now has its contract** (`notes/resim_contract.md`: authoritative deterministic re-sim). Remaining build work: the determinism conversion (CC first job) + the re-sim runner + legality checks. No longer a blank "design in its own session."
- **Matchmaking + orchestration (OWN-SESSION, NEXT DESIGN PIECE)** — press-queue → form 8 → assign/spawn headless match instance → lifecycle. The other half of "real MP" alongside re-sim. Pulled forward by the no-intermediates mindset. Needs `notes/multiplayer_architecture.md` + `server_decision.md`.
- **Cosmetic DLC packs** — fork presented (one-time, no gacha). Undecided. Paid never overlaps earnable/prestige.
- **Campaign-as-paid-DLC** — demand-driven posture (ship 10, build more if asked).

## Untouched — never actually discussed
- **Group Trials lobby flow** — ready-up, who picks map/window, start gate. (Scoring locked per-team; flow undesigned.)
- **Onboarding for non-SC2 players** — minimal for a *closed* beta (brief testers personally); full system is a launch concern.
- **Community hub** — Discord/subreddit. See `notes/gtm.md`.
- **IP/legal** — Random TD "spiritual successor" framing; confirm clearance.
- **Localization** — defer (English-first niche revival).

## Blocked on playtest data
- **Bronze/Silver/Gold threshold calibration.**
- **PVP seed-convergence** — shared-seed ranked could converge to identical mazes; eyeball in playtest.
- **Economy/supply re-tune** for the 25×14 board.

## Own session (large)
- **Matchmaking + orchestration** (see Direction-set — next up).
- **Juice / game-feel pass** — tweens, particles, hit-pause, shake, road shader. Light taste mockup exists.
- **Full GTM / marketing plan** — Steam page, capsule/tags/trailer, Next Fest/demo, streamer outreach. See `notes/gtm.md`.
- **Steam closed-beta mechanics** — app id ($100), Playtest vs beta branch, Win+Mac export presets, steampipe pipeline.
