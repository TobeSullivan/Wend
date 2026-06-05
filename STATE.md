# State

# STATE.md update — 2026-06-04

Paste the session entry at the TOP of STATE.md's session log, and replace the
"Next step" / relevant "Open questions" lines as noted. (Not reproducing the full
STATE.md here — it's large and Claude-Code-log-heavy; this is the prepend + the field
edits. Ask if you want the whole file rewritten instead.)

---

## Session-log entry (prepend to STATE.md)

**UI/visual design pass — design assistant (2026-06-04). Spec written, no code.**
Locked the game's visual system and applied it across every menu + PVP UI, all grounded
in the real art pack (`art.zip`) so Claude Code isn't stuck on missing assets. Outputs:
`design/VISUAL_SYSTEM.md` (canonical look, type fix, icon inventory, per-screen specs,
PVP UI) and `design/INMATCH_FIXES.md` (two scoped CC tasks: obstacle schema reopen +
chevron fix).
- **Visual system:** warm flat theme (`ui_style.gd` mockup block) is canonical; **blue
  dark-panel + wooden plank themes RETIRED** (delete from `ui_style.gd`).
- **Font bug found:** `fredoka.ttf` defaults to **Light 300** (variable font, "Fredoka
  Light") → text renders thin and "set bold" no-ops. Fix = ship static Fredoka-SemiBold,
  or `variation_embolden`, or drive the wght axis via `name_to_tag("weight")` + point the
  default font at the `.tres`. Promote weight+outline to a shared Theme.
- **Medals → stars** everywhere (no medal sprites exist; star assets do). 3★/2★/1★/empty.
- **Menus** (home, campaign select, PVE select, pause, settings) all redesigned to the
  system, text-forward buttons + confirmed real icons, on an **inert** grass+vignette
  backdrop (no fabricated decoration).
- **In-match:** grass fine (optional seasonal tiles + rubble scatter); **letterbox dead**
  (full-bleed grass confirmed in real screenshots); **obstacles** → real sized props w/
  overhang (schema reopen); **movement chevron** → fenced CC spec.
- **PVP UI:** drop the SCORE pill (placement is the judgment); arena wooden tray →
  toggle-able **leaderboard** (ranked 1–8, **player names**, lives, your row highlighted,
  OUT at bottom); tap name → spectate (live in run / last snapshot in build / "?" if
  unseen; one live board at a time, never 8); spectate safeguards (banner + green frame +
  Back button) and **hard rule: build phase force-returns to your own board**.

## Field edits

**Next step → add (design):**
- Decide player-facing names for PVE/PVP (lean: Co-op / Versus), then update labels.
- Hand `design/INMATCH_FIXES.md` tasks to Claude Code (chevron first — fully specced;
  obstacles second — schema reopen).
- Claude Code: migrate `pause_menu`, `settings_panel`, `win_panel`, `match_end_panel`,
  `home_screen`, `campaign_select`, `pve_select` onto the system tokens; delete the blue +
  wood styles from `ui_style.gd`; build the PVP leaderboard + spectate UI.

**Open questions → resolved this session:** medal representation (→ stars); menu backdrop
(→ inert static grass); PVP arena presentation (→ toggle leaderboard + spectate). **Still
open:** PVE/PVP player-facing naming.


Last updated: 2026-06-05

---

## Current focus

**▶ CURRENT STATE (2026-06-05): real online multiplayer is BUILT (Phases 0–4), all headless-verified, NOT yet live-tested. Big recent batch is UNCOMMITTED until this session's commit.** Done across the last sessions and folded into one uncommitted batch:
- **Obstacles → real sized props** (schema reopen; `src/resources/obstacle_*`); **in-match fixes** (chevrons build-phase only, zones on top, flag numbers); **PVP lives update mid-match** (`projected_lives`).
- **Networked PVP (host-authoritative ENet)**: transport seam (`src/net/`: match_transport/local/enet/net_protocol/net_match), lobby (`scenes/lobby.tscn` + `lobby.gd`, host/join + countdown + host-address hint), seed-synced identical maps, build-input relay + lockstep clock (coordinator decoupled via `driven_externally`), barrier lives resolution, disconnect forfeit. **Android debug APK builds** (`C:\dev\MazeBattleTD-debug.apk`). See session log for the per-phase detail + 2-process verification.
- **NEXT (user-side device test):** install the APK (`adb install -r`), Host on PC, Join from phone (LAN `<ip>:8771`, or port-forward UDP 8771 + public IP for internet); confirm a real PC↔Android match. Then: determinism hardening (fixed timestep + seeded crits — task deferred, pre-ranked), a full multi-round elimination → match-end placement playtest, and campaign threshold calibration (still blocked on real campaign playtest data).

**▶ Prior direction (2026-06-02): mobile-ready foundation FIRST, then multiplayer** — now realized. Architecture/costs locked in `notes/multiplayer_architecture.md` (round-barrier netcode; host-auth→dedicated; self-hosted Nakama; **no bots in ranked ever**; Steam-beta = $100 recoupable). Bots are scaffolding, not a mode. Trust-client for the beta; authoritative validation is a pre-ranked step.

**MOBILE IS RUNNING ON-DEVICE (Pixel 8 Pro), and the board-size direction is set (2026-06-02).** Touch input, the Android build pipeline, and several on-device playtest rounds are done. **Key reframe (from BTD6 reference, screenshots in `notes/screenshots`, gitignored):** the cross-platform-correct move is to design ONE board for the smallest screen (the phone) — PC scales it up — NOT a separate mobile version. So we are NOT keeping 40×22 + fighting zoom/scroll; we're shrinking the canonical board.
- **Current TRIAL (committed this session): half-size board 20×11** (`grid.gd` COLS/ROWS, same aspect as 40×22). Generated PVE/PVP maps are now 20×11 and **fit the phone screen with NO zoom, NO scroll** (`game_view` reverted to plain fit). Generator verified valid at all 5 scale tiers headless. User: "much better… right direction." **Authored campaign `.tres` still bake 40×22** — they look fine only because they're untouched; the trial is judged on PVE.
- **Android pipeline works** (JDK 17 + SDK build-tools 36.1.0/platform-36 + 4.6.3 templates + gradle template under `C:\dev\android-tools`; signed debug APK; recipe + gotchas in memory `reference-godot-android-export`). Rebuild+install loop is ~1 command + `adb install -r`.

**⏭️ NEXT SESSION (mobile UI polish + the board-size "big lift"):**
1. ✅ **In-match UI rebuilt to the HTML mockup — full-bleed battlefield + floating UI + dirt-road path (2026-06-03).** (My first attempt — reserved wooden bars — was REJECTED by the user as cramped/ugly; **don't reintroduce it**. See memory [[feedback_design_before_code]].) The agreed design is the user's `maze_battle_td_mockup.html` (saved in their Downloads): a full-bleed toned-down grass battlefield with the board filling the screen, the mob path drawn as a **cartoon dirt road** (gold fill + dark outline + highlight + animated white `>` direction chevrons), and **floating** rounded UI (no reserved frame): top-left Round/BUILD/Supply pills, top-right gold/kills/score pills, a floating top-right collapsible **tower dock** (stat rows with cost+coin + green `+`, red Sell), bottom **Pause/Build** and **Speed/Start-Round** clusters, blue selected-tower range ring. **Fredoka** font (wght-600) project-wide. Checkpoints use **flag** sprites. All built from the mockup as spec + the designer's `road_renderer.gd` helper; verified via PNG capture at 1× and 2×. See session log for files + remaining tweaks.
2. ✅ **Desktop-tested the 20×11 board (2026-06-03)** — captured generated PVE maps (tiers 1/3/5) on the real GL renderer @ 1920×1080. Verdict: direction **holds**; board reads coherent but **chunky/coarse** on a monitor (tiles ~79px), **low tiers (1–2) look sparse/empty**, and there's a **bottom letterbox** (board aspect 1.82 > play-rect 1.54 → fits-to-width, dead vertical space). One real **bug found + fixed**: bonus-zone radii (`bonus_zone.gd radius_for_magnitude`) didn't scale when the grid was halved (4-tile radius = ~40% of a 20-wide board vs ~20% on 40-wide) — zones swallowed the board + labels collided. Rescaled to a 2.25→0.85-tile lerp (widest ≈ old screen proportion); re-captured, zones now read sized-by-strength. **User chose: keep 20×11.** Letterbox + low-tier sparsity fold into the big-lift rebalance (#3).
3. **The big lift:** re-author/rescale the **campaign `.tres` maps** (M1–M10) to the new board size, and **rebalance** supply caps + thresholds for ~¼ the cells (100-tower supply won't fit a 220-cell board); reconcile the PVP map. Until then PVE/PVP (20×11) and Campaign (40×22) are inconsistent.

**How the touch build differs (in code):** `ui_layout.scale_factor()` = 2.0 on touch / 1.0 desktop, applied to UI fonts/sizes (rail, hud, pause) and rail/top-bar dimensions. Touch input is mode-less: tap an empty cell → preview → tap again to place; tap a tower → inspector+Sell; `emulate_mouse_from_touch=true` (so UI buttons work) with `build_controller` ignoring mouse on touch devices (game_view dispatches taps). On-screen **Pause button** in the rail (no Esc on mobile). Desktop mouse path unchanged.

**Render-fix re-verify CLOSED (2026-05-31).** User playtested the build-mode hover overlay on a dense map on the real renderer — memory holds, no leak/spike. The MUST-reverify item from round-2 fixes is resolved; the `Line2D` fallback is no longer needed unless a future regression appears.

**Active tracks (user-directed 2026-05-31):** (1) ✅ campaign missions 2–10 authored (awaiting feel playtest + threshold calibration); (2) multiplayer via local-sim-first plan — **Phases A–D done**: coordinator/board split, N-board lockstep + spectator camera, baseline bots, and the PVP ruleset. **First playable = PVP vs 7 bots is launchable from the home screen.** Remaining: PVE group lobby (E), arena grid (F), LP/rank/season meta (G), netcode (H) — plus bot difficulty tiers and a real-app PVP playtest. See session log.

**Playable through `8173085` (pushed to origin/main).** The game now boots through first-launch → home → and into either **Campaign** (mission 1 authored) or **solo PVE** (daily seeded Scale 1–5 generated maps). Full match loop, pause menu, settings, breakpoint-tuned upgrades, partial-score saving. Map resource framework + real procgen + UI/navigation all landed and verified.

**Most likely next steps:** more campaign missions; PVE backend (weekly/monthly windows, lobbies, leaderboards — deferred); audio (bus layout + sounds, which would make the Music/SFX sliders live); threshold calibration from real scores; or PVP. Open render fallback: if the build-mode overlay ever regresses on perf, replace the immediate-mode `_draw` dashes with a `Line2D`.

---

## ⏭️ NEXT SESSION

**Multiplayer is committed but never run live.** Priorities when the user returns:
1. **Real device test** (user-side): `adb install -r "C:\dev\MazeBattleTD-debug.apk"`; on PC PVP → Host; phone PVP → Join the shown `<LAN ip>:8771` (same Wi-Fi) or, for internet, forward UDP 8771 + share the public IP. Triage whatever breaks in live play (the netcode is only headless-verified so far). Rebuild the APK with `JAVA_HOME=C:/dev/android-tools/jdk17` + `Godot --headless --path src --export-debug "Android" <out.apk>`.
2. **Determinism hardening** (task #12, pre-ranked): fixed-timestep + seeded per-board crit RNG so spectated opponent boards don't drift mid-run. Not needed for correctness (lives reconcile at the barrier) — purely fidelity.
3. **Full match-end playtest**: a multi-round game that actually drains a board to 0 → elimination → match-end placement screen across two clients (only the disconnect path has exercised placement so far).
4. **Campaign threshold calibration** (still blocked on real campaign data): play campaign with `PlaytestLog.ENABLED` on (`src/scripts/playtest_log.gd`), read `user://playtest_log.jsonl`, tune `bronze/silver/gold_threshold` in `mission_0N.tres`, then flip ENABLED off.

---

## Testing checklist — 2026-05-31 session (everything below is verified headless only; needs real-app play)

### A. Campaign missions 2–10 (feel + calibration)
- [ ] Play each of missions 2–10; does the **difficulty curve** rise sensibly and does each mission's single lesson land? (2 mazing · 3 checkpoints · 4 zones · 5 slow · 6 crit · 7 multishot · 8 obstacles/supply · 9 economy · 10 capstone)
- [ ] **Thresholds are uncalibrated** (Bronze/Silver/Gold derived proportionally from mission 1). Is Gold achievable-but-stretchy? Note your scores per mission so I can calibrate.
- [ ] Campaign select shows all 10 playable, medals persist after a run.

### B. PVP vs 7 bots — the big untested-in-real-app area (Home → PVP)
- [ ] Match launches and builds 8 boards; you build your maze during build phase.
- [ ] **Spectator camera**: during run phase, Tab / ←→ cycle through boards; build phase snaps back to your board; the "Your board / Spectating board N" label is correct; framing/offsets look right; projectiles render on the correct board.
- [ ] **Lives HUD**: "Lives: N · alive X/Y" updates; round number is uncapped.
- [ ] **Lives transfers**: after each run phase, lives move by kill difference (out-kill → gain, get out-killed → lose); pool stays sensible.
- [ ] **Elimination**: a board at 0 lives drops out. If **you** get eliminated → "Eliminated — placed Nth" overlay with Spectate (keep watching) / Quit to Menu, and the match keeps running.
- [ ] **Match end**: last-standing → "Victory!" / placement result with Find New Match / Return Home.
- [ ] **Pause in PVP**: Esc shows the multiplayer pause (does NOT freeze the match) with "Quit Match".
- [ ] **STABILITY/PERF (key risk)**: play a PVP at **2× and 3×**, especially late rounds with dense mazes across 8 boards — watch memory/FPS. Headless showed an unconfirmed FX-related early-exit under heavy fast-forward; confirm the real renderer holds.

### C. Regression (the coordinator/board refactor touched the core loop)
- [ ] Solo **campaign mission 1** and a **solo PVE** map: full build→run→round→end, pause menu, settings, upgrade panel, fast-forward, partial-score saving all still work.
- [ ] Build-mode hover path overlay still fine (the earlier render fix), incl. a dense Scale 4/5 PVE map.

---

### Session log (chronological, most recent first)

**Obstacles → real sized environmental props (2026-06-04, Claude Code) — INMATCH_FIXES Task 1, NOT committed.** The locked schema-reopen: replaced the single placeholder rubble prop with curated, sized urban-decay props that block their footprint and may overhang.
- **Schema reopen (`map_resource.gd`):** new `obstacles: Array = []` (untyped, duck-typed like `bonus_zones` per the typed-cross-script-array memory) of `ObstacleDefinition` resources `{prop_id, origin, footprint}` + `blocked_cells()` helper. `obstacle_cells` kept as a deprecated 1×1-rubble fallback (loader uses it only if `obstacles` empty); all 10 `.tres` now use `obstacles`, generated maps never set the old field.
- **Prop registry (`src/resources/obstacle_props.gd`):** `PROPS` dict id→{tex, footprint, overhang, weight}; ~19 1×1 props (trees/drums/lamps/hydrant/tires/bins/rubble), cars/truck (1×2 / 2×2), 5 building ruins (1×2 / 2×2). `pick_for_footprint(rng,max_w,max_h)` weighted-picks (1×1 common, ruins rare). `FALLBACK_ID` for unknown ids.
- **Rendering (`obstacle.gd`):** new `setup(tex, origin, footprint, overhang)` — block = footprint rect; **base-anchored width-fit** so elevation art stands up and spills UPWARD beyond its blocked cells; tall/thin art height-capped at `OVERHANG_ROWS=3` tiles so a lamp doesn't tower. z=-5 (overhang is cosmetic, never blocks; towers above draw over it — accepted).
- **Loader (`map_loader.gd`):** `_setup_obstacles(map)` consumes `map.obstacles` via the registry (`_spawn_obstacle`), blocks every footprint cell; 1×1 fallback for legacy cells. Dropped the `OBSTACLE_TEX` const.
- **Generator (`map_generator.gd`):** replaced the 1×1 scatter with sized placement — **budgeted by blocked CELLS** (target = old `tier*2..tier*3+1`, so difficulty unchanged), each prop's full footprint kept clear of edge columns + reserved + re-validated with `_compute_path` (drop if it seals). Emits `ObstacleDefinition`s.
- **Campaign migration (one-shot tool, deleted):** per mission, every existing obstacle cell → a varied 1×1 prop (footprint UNCHANGED → the 2026-06-04 rescale balance preserved), plus a small per-mission budget of validated multi-cell promotions (M1/M10=2, most=1, **M8 "Tight Quarters"=0**). Results: M1 7props/2multi … M8 11/0 … M10 7/2; all paths valid, all saves clean.
- **Curated art imported** into `src/assets/environment/{props,building_ruins}` (14 new props + 5 ruins; `--headless --import`). New scripts `obstacle_definition.gd`/`obstacle_props.gd` have no `.uid` yet (generated next editor open; `.tres` ref by path, harmless).
- **Verified** (throwaway harnesses, deleted): headless build of all 10 campaign + PVE 1–5 + PVP-8 → **0 fails** (valid path each, every footprint cell blocked, `blocked.size()==footprint union` so overhang stays buildable, all prop_ids resolve, multi-cell props present across campaign/PVE/PVP); real-GL PNG captures of M1/M8/PVE-t5 read as varied real props with ruins overhanging cleanly, board legible; clean headless boot, zero errors. **NOT eyeballed in live play / on phone; NOT committed** — left for the user to judge prop sizing/density on desktop+phone first.
- **Three follow-up polish fixes (same uncommitted batch), user-directed, verified via real-GL build+run captures:** (1) **Chevrons are build-phase only** — `road_renderer.set_chevrons_visible()` toggled from `build_controller._on_phase_changed` (visible iff phase=="build"); during the run they were just noise over the mobs. Confirmed gone in a run-phase capture. (2) **Bonus zones now render ON TOP** (`bonus_zone.gd` z_index −60 → 50) so the translucent fill + label stay readable; props/towers/road were burying them. (3) **Checkpoint flag numbers** (`map_loader._setup_markers` banner fraction): measured the flag texture (red banner centroid = frac 0.559 ≈ the old 0.558, but a pennant is top-heavy so centroid reads high). Iterated 0.558 → 0.45 (user: too low) → **0.50** (settled — digit centered on the banner body, verified).

**Multiplayer Phase 0 — transport seam built + ENet connection verified (2026-06-04, Claude Code) — NOT committed.** First concrete step of the approved netcode plan (`plans/reactive-questing-platypus.md`; arch in `notes/multiplayer_architecture.md`). New `src/net/`:
- **`net_protocol.gd`** — wire message shapes (Dictionaries with a `t` type): lobby (LOBBY_STATE/SET_NAME/START_MATCH), build inputs (BUILD_INPUT place/sell/upgrade, READY), clock/barrier (CLOCK, RUN_DONE, RESOLUTION, MATCH_END) + builders. DEFAULT_PORT 8771, MAX_PLAYERS 8.
- **`match_transport.gd`** — abstract seam (Node): signals `received(from_id,msg)`/`peer_joined`/`peer_left`/`connection_succeeded`/`connection_failed`/`server_closed`; methods start_host/start_join/close, is_authority/unique_id/peer_ids, send_to_authority/broadcast/send_to. The pivot-insurance layer (host-auth now → dedicated/Steam/Nakama later = swap subclass).
- **`local_transport.gd`** — single-process passthrough (solo/PVE/bot-practice); authority=true, sends loop back to `received` so the same handlers run locally.
- **`enet_transport.gd`** — host-authoritative over ENet; one reliable relay RPC `_recv`; id 1 = authority; clients send_to_authority, authority broadcast/send_to. Owned by SceneManager (stable tree path so RPC resolves on both ends).
- **Verified**: two real headless processes connected over 127.0.0.1 and exchanged messages BOTH ways (client→host and host→client); parse/load check passes; clean boot. (Throwaway 2-process test + parse harness, deleted.)
- **Gotcha hit + saved** [[reference_godot_classname_cycle]]: new `class_name` scripts created outside the editor aren't in the global class cache → headless `extends ClassName` fails until an editor scan. Fixed by `extends "res://..."` by PATH + preload aliases (the project's existing rule).
- **Reorder note vs plan**: P0's coordinator-authority decouple folds into P2 (only testable once inputs/clock flow through the transport); seeded-crit determinism folds into the later fixed-timestep hardening pass (trust-client makes it non-essential for v1 correctness).

**Multiplayer Phase 4 — disconnect handling + Android APK + internet path (2026-06-04, Claude Code) — NOT committed.**
- **Disconnect handling** (`net_match.gd`): host maps a dropped peer→seat (via `seat_by_peer`, threaded lobby→SceneManager→NetMatch; the transport persists so ENet ids are stable) → forfeits that board (eliminated, worst placement), broadcasts RESOLUTION, and ends the match if ≤1 board remains. Clients handle the host vanishing (`server_closed` → `net_end_match`). **Verified** (2-proc, deleted): client quit mid-match → host forfeited it, match ended, **place_host=1 / place_client=2**, 0 errors.
- **Android APK BUILDS** ✅ — `Godot --headless --path src --export-debug "Android" C:\dev\MazeBattleTD-debug.apk` produced an 82 MB debug APK, exit 0 (toolchain from `reference_godot_android_export` still good: JDK17 + SDK + 4.6.3 templates + debug keystore under `C:\dev\android-tools`; `JAVA_HOME=C:/dev/android-tools/jdk17`). Not yet installed/run on a device.
- **Internet path**: ENet already works to a public IP; the lobby's Join field takes any address; the host's ROOM view now shows "Same Wi-Fi: Join at `<LAN ip>:8771`" + the internet note (forward UDP 8771, share public IP). Remaining is USER-side only: port-forward the router, `adb install -r` the APK to the phone, and a real PC↔Android match.
- **Net status**: Phases 0–4 all built + headless-verified (transport, lobby+seed-sync, input relay + lockstep clock, barrier lives, disconnects, APK). NOT eyeballed in live play / on a phone; NOT committed. Match-end placement screen is exercised by the disconnect path now (placement set correctly) but a full lives-drain elimination over many rounds is still untested. Determinism hardening (fixed timestep + seeded crits, task #12) deferred — pre-ranked concern.

**Multiplayer Phase 2 — build-input relay + lockstep clock + coordinator decouple (2026-06-04, Claude Code) — NOT committed.** Two real clients now build and advance in sync over ENet, seeing each other's boards live.
- **New `src/net/net_match.gd`** — the per-match driver bridging the local sim to the host-authoritative protocol. HOST runs the real `MatchCoordinator` clock + `resolve_lives` and broadcasts CLOCK / RESOLUTION / MATCH_END + relays each client's build inputs to everyone; CLIENT's coordinator is `driven_externally` (no self-clock) and mirrors the host, sending its own inputs + ready vote up. Each client sims ALL boards locally → full live opponent boards for free; only discrete inputs + clock + per-round lives cross the wire. Created by `main.gd` after a networked `build_match`.
- **`match_coordinator.gd` decoupled** (folds in the old P0 task): `driven_externally` flag (clients skip the self-clock in `_process`); `net` ref; `set_board_ready`/`is_board_ready`/`ready_count` route to the host on clients; new client-driver methods `net_enter_run`/`net_enter_build`/`net_set_build_time`/`net_end_match`/`_clear_all_mobs`.
- **`build_controller.gd`**: `net`+`seat`; local place/sell/upgrade relay via `_relay_place/_relay_sell/on_local_upgrade` → `net.submit_local_input`; inbound `apply_remote_place/sell/upgrade` (force-apply, owner-authoritative; never re-relay). `_sell_tower_at_cell` now returns bool. `tower_drawer` relays local upgrades; `round_manager.net_spend` (clamped best-effort spend for replicated opponent economy).
- **Verified** (throwaway 2-process ENet harness, deleted): host places a tower → appears on the client's replica of the host board; client places → appears on the host's replica (bidirectional relay ✓); both ready → host starts the run → client mirrors `phase=run` (lockstep clock ✓); **0 script errors**; clean boot. **Gotcha**: lingering headless Godot procs from background test runs hold the UDP port + run stale code — kill them between runs (`Get-Process Godot | Stop-Process`).
- **P3 VERIFIED (2026-06-04)**: a full round completing + transferring lives across two real ENet clients. Test (deleted): host built 8 towers, client built none; round 1 ran to completion; **both processes agreed exactly — b0=117, b1=83** (host +17 / client −17, zero-sum, matching `resolve_lives`). Notably the client's *cosmetic* view of the host board's kills drifted (16 vs the host's 17) but the **authoritative RESOLUTION reconciled lives identically on both sides** — exactly the round-barrier/trust-client design (in-run spectate may drift; lives are truth at the barrier). **Match-END placement (MATCH_END) is code-only / not yet exercised** (needs many rounds to drain 100 lives to elimination) — small surface on the same proven mechanism. **Remaining: P4 (internet host + Android + disconnects).**
- **Test gotchas**: headless runs FAST, so frame-count windows give too little game time — gate on the event (round==2) + bump `Engine.time_scale`; and background test launches race on the port/files — launch host via tracked background, client foreground, no trailing `rm`, kill Godot between runs.

**Multiplayer Phase 1 — seat generalization + lobby + seed-sync wiring (2026-06-04, Claude Code) — NOT committed.** User confirmed: build the lobby from the locked visual system (no design doc exists).
- **`map_loader.build_match` generalized**: new params `local_index` (the local player's seat; default 0) + `use_bots` (default true) + `player_names`. The LOCAL board is laid out at world ORIGIN (`_board_offset` reworked) so all existing mouse/cell math stays exact regardless of seat. UI/game_view/leaderboard now bind to `local_index`, not hardcoded 0. Networked matches pass `use_bots=false` (no bots) + real lobby names. **Verified headless**: solo (board0 origin) + bot-PVP (8 boards, bot on board1, board0 origin) UNCHANGED; networked-style (4 boards, seat 2 at origin, zero bots, name "Me" at seat) correct.
- **`scene_manager.gd`**: owns the transport (autoload → persists across lobby→match + stable RPC path); `goto_lobby()`, `net_host()/net_join()/net_close()`, `start_networked_pvp(seed,tier,count,seat,names)` (every client generates the IDENTICAL map from the shared seed, builds with own seat, no bots, transport kept alive).
- **`main.gd`**: networked branch (transport!=null → seated no-bot build); solo/offline-bot path unchanged.
- **`home_screen.gd`**: PVP hero button → `goto_lobby()` (was direct-to-bots `start_pvp`, which stays as offline practice entry).
- **`lobby.gd` + `scenes/lobby.tscn`** (new, from `ui_style` helpers): CONNECT view (name + Host/Join+address + Back) and ROOM view (ranked player list, host Play at ≥2, **auto-countdown from 10 at 8**, Leave). Host owns the authoritative player list + seats, broadcasts LOBBY_STATE; clients render it + SET_NAME on connect; START_MATCH broadcasts the seed → all load the match on their own seat.
- **Verified**: lobby scene instantiates headless with zero errors; clean full boot; real-GL captures of CONNECT + ROOM views read on-brand (card/grass/green-go/red-danger). **NOT yet tested end-to-end across two real clients** (the Phase 1 acceptance — two devices into the SAME seeded map). Transport round-trip already proven (P0). **Next: P2 — build-input relay + lockstep clock** (and the coordinator-authority decouple lands here). ⚠️ In-match clock/inputs are NOT synced yet — Phase 1 only gets both players into the same map; each runs its own clock until P2.

**PVP lives now update mid-match, not just at round end (2026-06-04, Claude Code) — NOT committed.** User: lives "cant just be a mystery until the end." `match_coordinator.projected_lives(board)` returns the live zero-sum projection during the run (`lives + n*my_kills_this_round - total_kills`, same math as `resolve_lives`; settled lives outside the run; can go negative → callers clamp). `hud.gd` shows it on the lives pill and **polls in `_process` during the PVP run** (a local kill fires `kills_changed`, but an OPPONENT's kill shifts my projection with no local signal, so poll). `leaderboard_panel.gd` ranks + displays by `projected_lives` and re-refreshes on a 0.2s throttle while open during the run. Verified headless: projection matches `resolve_lives` exactly, is zero-sum, build-phase shows settled lives. Latency-tolerant by design (kill counts are what sync under real netcode).

**Chevron rework + in-match UI fixes (2026-06-04, Claude Code) — road_renderer/tower_drawer/map_loader, COMMITTED.** A round of user-directed polish, mostly on the road direction chevrons, plus two tower-dock fixes and numbered flags. Verified via real-GL captures (throwaway harnesses, deleted) including a real match driven into the run phase.
- **Chevron fade — root-caused + fixed, THEN rewritten.** The "fade in/out" the user flagged since the design notes was a canvas-shader gotcha: `COLOR *= texture(TEXTURE, scrolled_uv)` multiplies the auto-pre-sample (texture at the *original* UV) by the scrolled sample → the *intersection* of the chevron at two positions, which collapses as the scroll separates them (animated by `TIME`, so invisible at t≈0 — which is why earlier "fixed" captures lied; ALWAYS verify time-animated shaders across several t). Saved as memory [[reference_godot_canvas_color_presample]]. **Then replaced the whole tiled-texture approach** with **discrete rotated chevron Sprite2Ds** placed at arc-length intervals along the committed path — because the tiled texture also WARPED at corners (a chevron on a bend smeared into a blob; the user's "arrows look crazy when turning"). Each chevron is now its own sprite rotated to the local travel direction (clean corners), with a subtle additive glow sprite behind it; scroll = a bounded arc offset advanced in `_process` (no fade possible, no per-frame allocation). All in `road_renderer.gd` (public API set_path/set_preview/clear_preview/configure unchanged).
- **Chevron look (user-directed):** colour warm terracotta `#d9531e` (was thin white, low-contrast); glow toned WAY down (subtle hugging halo, was a thick white-hot bloom); scroll 2× faster (~2 tiles/sec); ~1.5-tile spacing, ~0.4-tile tall. **Run-phase persistence verified** (16s into a real run, mobs walking + towers firing — chevrons stay solid; the "markers vanish in run" report was the old TIME-fade at run timing).
- **Tower dock (`tower_drawer.gd`):** removed the per-row **coin icons** from the upgrade rows (cost numbers stay); **restored the Total-damage display** the UI rebuild had dropped — the tower already tracked `damage_done`/`kills`, so added a live "Total damage  Nk · K kills" footer that updates each frame while open.
- **Numbered checkpoint flags (`map_loader._setup_markers`):** flags now carry their visit-order number (1,2,…). Centre measured from `level_marker_flag.png` (banner centroid is on the pole, ~56% up); digit centred via a square centre-aligned box (font 15). **Known gap:** a checkpoint in the board's TOP row has its banner+number partly tucked under the floating HUD pills (flags extend upward) — a HUD-vs-top-edge overlap, not addressed.

**Campaign big-lift — rescaled M1–M10 to 20×11 + rebalanced (2026-06-04, Claude Code), NOT committed.** Closed the standing inconsistency (campaign baked 40×22 while PVE/PVP run 20×11). Done via a one-shot validated tool (run as a scene so autoloads/`GameConstants` were live; deleted after) that loaded each `mission_0N.tres`, rescaled, and re-saved with `ResourceSaver`.
- **Geometry:** 40×22 → 20×11 is a clean **÷2 on both axes**. Entry/exit kept on the L/R edges (row halved); checkpoints remapped, deduped, and nudged off edges/entry/exit via a spiral search; obstacles remapped, edge-column-cleared, deduped, and **greedily dropped if they'd seal the path** (same validation the generator uses); zone centres remapped into the interior (type+magnitude kept).
- **Supply ~×0.6** (floored 15, rounded to 5): the board is ¼ the area but `TOWER_BASE_RANGE` (160px ≈ 3.3 tiles) is **unchanged**, so each tower covers a larger fraction of a 20-wide board → a comparable maze needs ~60% of the towers. New caps: M1-10 = 60/20/25/30/35/25/35/25/50/60 (was 100/35/45/50/60/40/60/45/80/100). Sits inside the generator's 20–100 band; rounds + mob_count + lesson character unchanged (M8 "Tight Quarters" kept 11 obstacles + tight 25 supply; M10 kept 6 zones).
- **Thresholds re-derived** with the generator's **exact `_derive_thresholds`** (consistent with PVE). **Grounded in the playtest log** (`user://playtest_log.jsonl`): real `final_damage` is **31k–151k after 1–3 rounds** and a full PVE run hit **~5.6M by round 10 / ~9.8M by round 12** — so the OLD authored campaign thresholds (M1 gold **2,500**) were broken placeholders (~100–1000× too low, gold in seconds). New derived golds (M1 **566k** … M10 **1.25M**) are the correct order of magnitude. Still SOFT → task #3 (campaign playtest calibration) tunes them with `PlaytestLog.ENABLED` on.
- **PVP needed no work** — PVP maps are generator-produced at 20×11 already (no authored `.tres`); the only inconsistency was campaign.
- **Verified:** all 10 build through `map_loader.build_match` with valid paths + zero errors; real-GL captures of M1 (sandbox, 3-cp loop, 4 zones) and M8 (tight, 11 obstacles) read coherent and fill the screen. Updated `grid.gd` (no longer a "trial"; campaign now also 20×11) + `map_resource.gd` default grid → 20×11. **NOT eyeballed in live play / on phone; NOT committed.**
- **Note:** obstacles still render as the placeholder `rubble_pile_01.png` (INMATCH_FIXES Task 1 not done); the rescale preserved obstacle *cells*, so that task drops in cleanly later.

**Visual-system migration — all 3 locked UI chunks built (2026-06-04, Claude Code), NOT committed.** Executed the whole `design/VISUAL_SYSTEM.md` backlog in dependency order; every screen verified by real-GL PNG capture (throwaway harnesses, deleted). All from locked design — no new design invented.
- **Chunk 1 — Type/Theme foundation.** Confirmed the Fredoka weight bug headlessly: the variable font's wght axis is 300–700 with **default 300 (Light)**, so bare text renders thin. `fredoka_bold.tres` (wght 600) already existed + was the project `custom_font`, so weight was wired; the missing piece was outline recurrence. Built **`assets/ui/app_theme.tres`** (base Theme: default_font = the wght-600 variation + `font_outline_color #1a2012` + `outline_size 3` on Label/Button/CheckButton/OptionButton) and set it as `gui/theme/custom`. Now every text control inherits weight+outline — screens stop re-declaring it. Capture proved bare-300 (thin, no outline) vs themed (heavier + dark outline) on grass.
- **Chunk 2 — Menu migration (7 screens).** `home_screen` (grass+vignette backdrop, PVE/PVP equal hero buttons, Campaign tertiary, season pill, corner Settings/Quit), `campaign_select` (5×2 card grid, lesson labels, **star tiers**), `pve_select` (gold-lit Daily/Weekly/Monthly tabs, carded rows, green Play, gold star on best), `settings_panel` (card + top-right close), `pause_menu` (card, green Resume, terracotta Quit, **objectives rebuilt as 1★/2★/3★ rows** with score-to-beat + tick on reached/dim on not), `win_panel` (card, star language), `match_end_panel` (card, **medal→big star tier** + threshold **star rows** with ticks). **Medals→stars everywhere via a new asset-free `star_rating.gd`** (pure `_draw` 5-point stars — works in any checkout, no art-pack dependency). Rewrote `ui_style.gd`: deleted the **retired blue + wooden-plank styles** (kept icon infra `_tex`/`icon_rect`/`icon_texture`), added menu tokens (`menu_backdrop`+radial vignette, `apply_card`, `style_hero/go/danger/menu/tab_button`). Reused the in-match grass (`summer_grass_tile.png`, modulate .72/.80/.62) as the inert backdrop.
- **Chunk 3 — PVP leaderboard + spectate.** New **`leaderboard_panel.gd`** (replaces the thumbnail `minimap_panel.gd`/`minimap_tile.gd`, both **deleted**): left-edge toggle drawer, rows **ranked by lives**, position + **player name** + lives, **your row green-highlighted**, eliminated → **OUT** sunk to bottom, names ellipsis-truncate. Tap row → **spectate live during run** (`arena.focus_board`); build phase = no-op (hard rule). Coordinator gained `board_names` + `name_for()`; `map_loader` assigns "You" + spread pool handles for PVP and feeds `game_view.board_names`. **Spectate safeguards in `game_view`:** green inset frame + "Spectating <name>" green banner + always-present "← Back to your board" button, shown only during run-phase spectate; **build phase force-returns** the camera home (existing `_on_phase_changed`). **Dropped the SCORE pill in PVP** (`hud.gd` — keeps lives+kills). Action-strip "Map" button → "Ranking". Only the ONE spectated board renders live (list is text → never 8 live thumbnails).
- **Verification:** headless project parse clean; real-GL captures of home/campaign/pve/settings + pause/win/match-end (in a real solo match) + PVP leaderboard/spectate (real 8-board match) all correct; clean game boot. **NOT yet eyeballed on a phone / in live play; NOT committed.**
- **Known follow-ups (minor):** the in-match **non-PVP HUD score pill still shows a medal icon + "→Silver/Gold" next-tier text** (the live HUD wasn't in the 3-chunk scope — could swap to stars later); PVE/PVP player-facing naming still unresolved (home uses "PVE"/"PVP"); leaderboard drops the old build-phase "last-seen snapshot study" (text list has no thumbnail — deferred, the hard-rule force-return covers the info-hiding intent).

**In-match UI rebuilt to the mockup + dirt-road path (2026-06-03, Claude Code) — many files, COMMITTED + pushed this session.** Two distinct attempts:
- **Attempt 1 (reserved wooden bars) — REJECTED.** I first removed the rail and built a reserved top-bar + bottom-strip frame themed with the `art/ui` wooden planks. The user hated it ("worst design I've ever seen"); a `--uidebug` overlay also exposed a real bug (nine-patch `StyleBoxTexture` min-size forced the bars to 176/216px, overlapping the board). All of that was torn out. **Lesson saved:** [[feedback_design_before_code]] — for visual work, get an agreed design first, don't iterate look-and-feel through code.
- **Attempt 2 (the keeper): the user designed it in a separate chat and gave me `maze_battle_td_mockup.html` (their Downloads) as the spec + a `road_renderer.gd` helper.** Built to match:
  - **Full-bleed battlefield** (`map_loader._setup_background`): one toned-down grass (`modulate (0.72,0.80,0.62)`) bleeding past the screen so there's never black; the 20×11 board fills the screen (camera `play_rect` = whole viewport now); faint cell grid via new `grid_overlay.gd`.
  - **Cartoon dirt road** for the mob path (new `road_renderer.gd`, a `Line2D` stack — outline/fill/highlight + animated white `>` direction chevrons via a scroll shader on a tiled chevron texture; updates only on path change, not per frame). Replaced the old animated-dash `_draw` overlay in `build_controller` (deleted). The road + mobs both follow an **orthogonal** grid path (new `pathfinder.compute_orthogonal_path` = 4-dir A* + collinear collapse) so corners are clean Ls and mobs stay ON the road; both fed the **horizontally-extended** path (`current_path_world`) so the road runs straight off the left/right edges (no forced stub).
  - **Floating UI (no reserved frame):** rewrote `hud.gd` (top-left Round/BUILD/**Supply**(tower-sprite icon) pills, top-right gold/kills/score pills), `action_strip.gd` (bottom-left Pause icon + Build chip; bottom-right Speed + green Start-Round; center build-confirm prompt; PVP Map toggle), `tower_drawer.gd` (top-right collapsible **dock**: stat rows with **cost+coin** per row, green `+`, red Sell). `ui_style.gd` gained flat pill/chip/dock/button helpers (`pill_box`, `style_flat_button`, `stat_box`, `dock_box`). Blue selected-tower range ring in `build_controller`. Tap-leakage guard kept (drawer/minimap `covers()` via panel rect).
  - **Font:** downloaded **Fredoka** (Google OFL) → `src/assets/fonts/fredoka.ttf`; a `fredoka_bold.tres` FontVariation (wght 600) set as the project default font (`project.godot [gui] theme/custom_font`).
  - **Markers → flags** (`map_loader._setup_markers` uses `level_marker_flag.png`, base-anchored).
  - Verified by PNG capture at 1×/2× (throwaway `_capture_ui` harness + `--uidebug` overlay, both deleted); clean headless boot.
- **Open tweaks for tomorrow (all minor, user testing on desktop):** chevron density/speed + flag size/anchor (judge in motion/on-device); a couple gradient/grass-tone approximations of the mockup's CSS; the **path-balance side-effect** (orthogonal routes are longer than the old diagonal ones → mob timing shifts, thresholds already uncalibrated). Possible deeper ask: entry/exit sliding along the edge when the player walls the exact cell (currently lead-in/out is fixed to the entry/exit row).

**Desktop-test of the 20×11 board + zone-radius fix (2026-06-03, Claude Code) — bonus_zone.gd modified, not committed.** Ran the cheap pre-big-lift check (NEXT-SESSION item 2). Computer-use couldn't grant the loose `Godot.exe` (resolver only matches Start-menu apps), so I captured the real GL renderer to PNG instead: a throwaway `_capture_board` host generated a PVE map, built the real match (UI frame + camera) into itself @ the project's 1920×1080, saved the viewport, quit; ran for tiers 1/3/5 (deleted after). **Findings:** (1) board is **chunky/coarse** scaled up — defensible (BTD6-on-desktop) but **low tiers look sparse/empty**; (2) **bottom letterbox** — board aspect 1.82 > play-rect 1.54, fits-to-width; (3) **bug: bonus-zone radii never scaled with the halved grid** — `radius_for_magnitude` returned up to 4 tiles (8-tile diameter = ~40% of a 20-wide board vs ~20% on the old 40-wide), so zones dominated + labels collided (worst at tier 5). **Affected generated PVE/PVP maps live, not just the campaign.** **Fix:** replaced the formula with a `lerpf(2.25, 0.85, t)` inverse (t from mag 10→100) so the widest zone ≈ the old screen proportion and high-mag zones stay tight-but-distinct (not all clamped to one floor — magnitudes are uniform 10–100, ~40% sit high). Re-captured tier 3/5: zones now read sized-by-strength, no pile-up. **User chose to keep 20×11.** Letterbox + low-tier sparsity deferred into the big-lift rebalance.

**Mobile on-device playtest + Android pipeline + half-size board trial (2026-06-02, Claude Code) — committed this session.** Got the game building, installing, and iterating on a real Pixel 8 Pro, then landed the board-size direction.
- **Android build pipeline stood up from scratch** (command-line, no Android Studio): Microsoft OpenJDK 17, Android SDK (cmdline-tools + platform-tools + build-tools 36.1.0 + platform-36), Godot 4.6.3 export templates, gradle build template — all under `C:\dev\android-tools`, user-level env. Debug keystore + Android export preset (`export_presets.cfg`, gitignored). Four failures each taught a gotcha (now in memory `reference-godot-android-export`): missing `import_etc2_astc` (silent empty config error), `.build_version` belongs at `android/.build_version` not inside `build/`, `.gdignore` must be INSIDE `android/build/` (else Godot pollutes the gradle tree with `.import` files → merge fail), keystore via env vars. Signed APK builds; `adb install -r` + monkey-launch loop established.
- **On-device touch iterations** (each = a rebuild+reinstall): (a) `emulate_mouse_from_touch` was OFF → all UI buttons dead; turned ON + made `build_controller` ignore mouse on touch devices so taps don't double-fire. (b) **mode-less tap-to-build** — tap empty cell → preview → tap again to place; no "Build" mode toggle (hidden on touch). (c) pan/zoom removed (felt wrong), then (d) re-added as 2× zoom + scroll, then (e) **removed again** in favor of the smaller board. (f) On-screen **Pause button** (no Esc on phone). (g) **2× UI scale** on touch via `ui_layout.scale_factor()` — user confirmed the size is right & readable.
- **BTD6 reference (screenshots) reframed the board problem:** BTD6 uses ONE map that fits the phone because it's designed at phone-legible density; PC scales up. So the fix isn't a camera trick or a mobile port — it's a coarser canonical board. **Trial: halved 40×22 → 20×11** (`grid.gd`). Generated PVE/PVP maps now fit the phone with no zoom/scroll; generator validated at all 5 tiers. User: right direction. Campaign `.tres` still 40×22 (big-lift pending — see Current focus / NEXT SESSION).
- **Open:** right rail still too large at 2× (needs a sliding drawer + bottom control strip + `art/` UI elements); desktop test of the 20×11 board pending; campaign map re-scale + rebalance is the big lift.

**Mobile touch-input foundation built & headless-verified (2026-06-02, Claude Code), not committed.** First step of cross-platform-from-the-start (plan: `C:\Users\tobes\.claude\plans\peppy-wiggling-whale.md`). Adds a deliberate touch path alongside the unchanged mouse path; PC/Steam behavior is untouched. Renderer/stretch were already mobile-appropriate, so this was a bounded input pass, not a rewrite.
- **Interaction model (agreed):** the right rail is the context panel. Tap an empty buildable cell → ghost preview (range + green/red valid tint) + rail shows **"Build here — Ng / [Build] [Cancel]"**; **tap the same cell again = build** (fast mazing, no reaching to the rail); tap a different valid cell moves the preview. Tap a tower → inspector **+ new [Sell] button** (touch has no right-click). One tower type, so it's a build-confirm, not a radial. Camera: 1-finger drag = pan, 2-finger = pinch-zoom + pan. Landscape locked.
- **`project.godot`**: `[display]` stretch `aspect="expand"` + `handheld/orientation="landscape"`; `[input_devices]` `pointing/emulate_mouse_from_touch=false` (critical — stops a tap also firing a synthetic mouse click that would double-fire vs the explicit touch path; Control nodes still get touch natively).
- **`build_controller.gd`**: new `handle_tap(world)` → `_tap_cell(cell)` state machine (preview/confirm/move/select), `confirm_pending_build()`/`cancel_pending_build()`/`sell_selected_tower()`, signals `build_pending(cell,cost,affordable)`/`build_pending_cleared`, parked-preview helpers `_set_pending`/`_clear_pending`, shared `_apply_ghost_color`. Per-frame hover-follow in `_process` is gated to mouse mode (`_touch_mode`, seeded from `DisplayServer.is_touchscreen_available()`, flipped off by any real mouse event). Mouse `_input` placement path unchanged.
- **`game_view.gd`** (owns the Camera2D): new touch `_input` — tracks touches, 1-finger still-lift = tap dispatched to `local_build_controller.handle_tap` (gated to play_rect, screen→world via the centred-camera model), 1-finger drag = pan, 2-finger = pinch-zoom-about-centroid (clamped 0.5×–4× the fit zoom) + pan. Mouse-wheel zoom added for desktop parity. Stores `_fit_zoom` in `_focus`.
- **`action_rail.gd`**: docked **build-confirm prompt** (label + Build/Cancel) wired to the new signals; **[Sell]** button in the inspector; tap targets enlarged (action buttons 42→52px/font 18, upgrade rows 36→44px); controls hint updated off right-click.
- **`map_loader.gd`**: injects `game_view.local_build_controller = boards[0].build_controller`.
- **Verified headless** (throwaway harness `_touch_test`, deleted; built a real solo match via map_loader and drove `_tap_cell` directly): tap→preview (build_pending fired); tap-same→tower placed (gold 250→240, −10 = TOWER_COST; build_pending_cleared fired); tap B→C moves preview; cancel→no pending/no tower; select→sell (tower removed, +3 refund). All 7 checks passed, zero script errors; boot smoke clean before+after. **NOT yet eyeballed on a real renderer or a phone.**
- **NEXT:** (1) desktop eyeball — flip `emulate_touch_from_mouse=true` locally to drive the touch flow with a mouse (preview→confirm, pan/zoom, Build/Cancel + Sell, cell-under-camera accuracy); confirm the mouse path still works (hover ghost, click-place, right-click sell) in solo + PVP. (2) **Android test (user, manual)** — needs the Android build template + SDK installed in the Godot editor (one-time editor setup, not scriptable headless), then export an APK and sideload to a phone: landscape lock, tap-preview/tap-again-build, pan/pinch, select+Sell, rail legibility/tappability. iOS deferred ($99 + provisioning). Then commit.

**Multiplayer architecture + cost research; mobile-first decision (2026-06-02, Claude Code).** No code — research + decisions, captured in `notes/multiplayer_architecture.md` (the reference for the MP rollout). Key outcomes:
- **PVP-vs-bots is NOT a shipping mode** — bots were always cold-start scaffolding (`DESIGN_MODES.md` modes are Campaign/PVE/PVP, all human). Playtest log confirmed it: user won all 5 PVP-vs-bot matches in 1–3 rounds (bots far too weak). **Decision: don't balance bots.** Also confirmed the log has **zero campaign data** (all `mission:0`, name "") — the planned campaign threshold calibration is blocked until a real campaign play session; the data was all PVE (mode 1) + PVP (mode 2).
- **No bots in ranked, EVER** (user directive) — bot-climbing poisons the ladder. Thin queues solved by **shrinking the lobby (8→6→4, already supported via `pending_board_count`) + widening rank bands under load (bronze vs plat)**, never bot-fill. More legitimate AND less code.
- **MP is netcode-friendly**: round-barrier sync (boards independent within a round; only kill-counts cross at the boundary; mob-HP deterministic from round+seed). In-match transport is cheap/easy; the hard+costly parts are cross-platform identity, matchmaking, anti-cheat, ops. Spectate can be near-free via determinism (re-sim opponent board from frozen layout + seed + death events).
- **Rollout (pivot-safe)**: define `MatchTransport` (over Godot `MultiplayerPeer`) + `MetaBackend` interfaces → loopback→LAN host-authoritative (trust-client) → Steam-relay beta w/ join codes → dedicated headless coordinator + **self-hosted Nakama** backend for mobile/scale. Steam networking is a beta convenience, never the foundation (PC/Mac-Steam only; consoles forbid raw P2P).
- **Costs**: Steam beta = **$100 one-time, recoupable** (the whole near-term bill). Hosting is <0.5% of revenue at every tier (Hetzner Nakama ~$16–130/mo). Real costs are the platform cut (30%, or 15% mobile under $1M/yr) + console *effort*. Sales projections (1k/10k/50k/100k units) + the tax model (you're taxed on the net you receive, minus expenses — never the platform's 30%) are in the notes file.
- **NEXT ACT (user-directed): a mobile-ready foundation pass BEFORE multiplayer** — build cross-platform from the start to avoid PC-first-then-refactor. Renderer (`gl_compatibility`, incl. `.mobile`) + stretch (`canvas_items`) are already mobile-appropriate; `ui_layout.gd` centralizes layout (cheapest time to do this is now). Bounded work: touch-input layer (tap-to-place replacing hover-ghost, drag-pan + pinch-zoom on the existing `game_view` Camera2D), orientation/aspect project settings, finger-sized tap targets, an Android APK test export (free sideload; iOS deferred — needs $99 + provisioning). NOT a rewrite. Plan + build next.

**Committed + pushed `a6c11a2` (2026-06-02).** The whole adjustment + UI-frame batch below landed on `main` and was pushed to origin. Also flipped `PlaytestLog.ENABLED` to false (off) — the `user://playtest_log.jsonl` data persists on disk, so thresholds can still be calibrated from it later; just re-enable to log more.

**PVP ready-vote + no fast-forward (2026-06-02), committed in `a6c11a2`.** PVP is lockstep, so unilateral start / fast-forward were wrong.
- `match_coordinator`: PVP ready system — `set_board_ready(board, value)` tracks per-build-phase votes (`_ready_set`, cleared at each run start); the run starts early only once every active board has readied, else it waits for the build timer. `request_start_now()` is now a no-op in PVP. New `ready_changed` signal + `is_board_ready`/`ready_count` for the UI. Bots auto-vote ready (`bot_controller`) once they've nothing useful left to build/upgrade.
- `action_rail`: in PVP the Start button becomes a **Ready** toggle showing `✓/○ Ready (n/m)`; the **Speed button is omitted** and `_apply_time_scale` forces 1x. Solo/PVE keep Start Round + Speed. Verified headless (9/9): no speed button in PVP, unilateral start ignored, ready vote waits for all then starts, 1x forced; solo Start Round + Speed intact.
- **Bot crash fix confirmed in-app** — the user's PVP no longer crashed.
- **Board fit — "shrink the chrome" (user-chosen)**: dropped the separate left dock; the PVP arena minimap now lives in the bottom strip of the right rail (`ui_layout.arena_region`, minimap on layer 11 above the rail). Both modes reserve only the right rail, so the board spans the full screen width and the PVP letterbox shrinks from ~140px to ~80px with the whole board still visible. The top/bottom bands can't be fully removed without clipping the board's sides (40×22 is wider-aspect than the framed area) — user accepted that. `LEFT_DOCK_W` removed; `play_rect` no longer varies by mode. Verified (9/9): board frames inside the full-width play rect + fills width in all 3 modes; minimap tiles sit in the rail strip; fog/snapshot/lives/click-focus intact.

**PVP build-phase crash + board fill (2026-06-01), not committed.** User: PVP crashed on the 3rd load, during the BUILD phase ("stuttered generating the opponents' boards then crashed"), before any run/towers/projectiles — PVE never crashes.
- **Root cause: synchronized bot pathfinding spike.** The 7 bots are created together so their `ACTION_INTERVAL` timers fired on the SAME frame; each action runs a burst of A* (`SAMPLE_K` candidates × `compute_full_path`), so ~7×12 ≈ 90 A* runs in a single frame, repeating every 0.2s. On a heavy map that's a multi-second frame hitch (the "stutter") long enough to trip the OS GPU watchdog → process crash. Confirmed NOT a memory leak (6 build/free cycles: nodes/orphans/mem flat at 28.6MB).
- **Fix**: a per-frame bot-action budget on `match_coordinator` (`MAX_BOT_ACTIONS_PER_FRAME=2`, reset each frame which runs before the bots); `bot_controller` calls `try_consume_bot_action()` and retries next frame if over budget (keeps its timer). Also `SAMPLE_K` 12→8. Verified headless on a scale-5 (3-checkpoint, heaviest A*) PVP: max bot actions in any single frame = 2 (was ~7), bots still build fully (63 towers, ≥9/board over 5s). The spike is gone.
- **Board fill**: `PLAY_MARGIN` 0.96→1.0 so the board fills the play-rect width. A small top/bottom dark letterbox is inherent (the 40×22 board is a wider aspect than the framed play area) — not slack.
- **STILL UNCONFIRMED on the real renderer** — the crash itself can't be reproduced headless (dummy renderer). If it recurs, capture stderr (`... 2>&1 | Tee-Object pvp_crash.log`) to get the real backtrace.

**UI-frame playtest fixes (2026-06-01), not committed.** From the first real-app look at the reserved-frame UI:
- **PVP 3x crash — root-caused to FX.** Every board (incl. the 7 hidden ones) spawned damage-number + death-FX nodes on every hit/kill; at 3x with 8 boards farming that was the load behind the stall/crash. `mob.gd` now gates both FX spawns on `is_visible_in_tree()` — only the board actually on screen spawns cosmetic FX (the kill credit / hp reset still run on every board). Verified directly: visible board (solo + PVP local) produces FX on a kill; a hidden PVP board produces zero; node count stays bounded at 3x.
- **"Invisible blocker" on the board edges** — the grass was padded 5 tiles beyond the grid, so the off-grid margin looked buildable but wasn't. `map_loader._setup_background` is back to grass = exactly the grid; its edge is now the visible buildable boundary.
- **Grass showing behind the UI / "menu on board"** — chrome panels were translucent. `ui_style` BG/BG_BAR are now fully opaque, so the top bar / rail / dock are solid and the board reads as reserved out of the frame.
- **Letterbox around the board** is now the dark clear colour (`project.godot` `default_clear_color`) instead of grey, framing the play area cleanly.
All verified headless (FX gate direct test; all-mode builds clean; bounded nodes at 3x). Visuals still want a real-app re-check.

**In-match UI pass — reserved frame (2026-06-01), not committed.** Full UI rework: the board was full-screen so every HUD panel overlapped placeable tiles. Now the board is **camera-fit into a reserved play rect** with fixed UI zones around it (top bar / right rail / left PVP dock); nothing overlaps the play area. Plan approved; built in 6 headless-verified phases. See `DESIGN_MODES.md` "In-match UI frame".
- **`ui_layout.gd`** (new): single source of truth — `TOP_BAR_H=52`, `RIGHT_RAIL_W=340`, `LEFT_DOCK_W=220`, `play_rect(is_pvp, vp)`. The camera, bars, dock, and the board click-gate all read it.
- **`game_view.gd`** (new, replaces `arena_view.gd`): a `Camera2D` in EVERY mode now (solo had none). Fits the focused board into the play rect via `zoom = min(play/board)*0.96` + a screen offset so the board centres in the play rect, not the screen. Run-phase spectate-on-click via `focus_board(i)`. Board tradeoff: ~82% solo / ~71% PVP, fully visible.
- **`build_controller.gd`**: clicks outside `play_rect` are ignored (one screen-space gate replacing the old per-panel hit test). Tower selection now emits `tower_selected` / `selection_cleared` (no more floating panel). New `toggle_build_mode()`. Esc-stack hooks (`is_upgrade_panel_open`/`close_upgrade_panel`) preserved for pause_menu, now backed by selection state. Hardcoded hint label removed.
- **`hud.gd`** → slim top status bar (round/phase/timer + gold/score/kills/lives). Start/Speed moved out.
- **`action_rail.gd`** (new): right rail — Build/Start/Speed (owns the run-phase fast-forward now) + the **docked tower inspector** (absorbs the deleted `upgrade_panel.gd`'s 6-stat UI) + objectives/hint when nothing is selected.
- **`minimap_panel.gd`**: docked into the left zone (smaller 94×62 tiles, 2 cols), big "last seen" panel centred over the play rect. `arena` ref → game_view.
- **`ui_style.gd`** (new): shared dark-panel / bar / accent-button styles applied to top bar, rail, dock, pause, settings, win, match-end. Also fixed `settings_panel` centring (same `PRESET_CENTER` bug as the pause menu).
- **Deleted**: `arena_view.gd`, `upgrade_panel.gd` (folded in).
- **Verified headless** (throwaway harnesses, deleted): frame geometry — board fits inside the play rect, fills it, play-rect maps onto the grid (solo + PVP, 6/6); rail — inspector show/hide, upgrade spends gold, objectives toggle, full Esc stack inspector→build→pause, Start→run (14/14); minimap regression docked — fog/snapshot/lives/click-focus + tiles inside the dock (14/14); full smoke — all 3 modes build + enter run, pause centred, settings open (5/5). **Visuals/feel still need a real-app playtest** (board size, panel legibility, placement matching the ghost under the camera).
- **NOTE**: new scripts `ui_layout/ui_style/game_view/action_rail.gd` have no `.uid` yet (generated on next editor open — harmless, they load via preload).

**Adjustment pass round 2 — playtest fixes (2026-06-01), not committed.** From the first real-app look at the adjustment-pass work:
- **PVP tower placement off-by-a-tile — FIXED (root cause).** `build_controller._input` computed the placement cell from `mouse_event.position` (raw screen coords) while the hover ghost used `get_global_mouse_position()` (world). Identical in solo (no camera) but divergent under the PVP spectator camera (zoom 0.92 + offset), so towers landed a tile off the ghost. Now both use the world mouse position. The upgrade-panel hit test stays in screen space.
- **Generated checkpoints are now randomized.** `map_generator._place_checkpoints` was near-deterministic (index-spaced x with ±2 jitter, fixed top/bottom y-bands) → every 1-cp / 2-cp map planted points in the same spots. Now fully random interior positions with a min-separation; the existing "keep the longest-path set, require MIN_PATH_RATIO" loop still guarantees traversal. Verified: 12/12 distinct layouts per tier, spread across the whole board, all maps still build a valid path.
- **Grey strip/border gone.** `map_loader._setup_background` now pads the grass `BG_PAD_TILES` (5) beyond the play grid on all sides, covering the 24px viewport slack at the bottom (solo) and the ~8% PVP camera framing margin that previously showed the grey clear color.
- **PVP "scoreboard" = the previews now show lives.** `minimap_tile` drew the lives subhdr with `draw_string(... HORIZONTAL_ALIGNMENT_RIGHT, width=-1 ...)`, which does NOT right-align → opponents' lives were invisible. Fixed to right-align within the tile width, so every preview shows that board's lives (and "OUT" when eliminated). The previews are the scoreboard.
- **HUD dropped "· alive X/Y"** (PVP) — who's alive is read off the previews. `coord` local removed (was now unused).
- **Tab-spectate prompt removed.** `arena_view` label no longer shows `[Tab]/[←/→]` hints (spectating is via clicking the minimap). Keys still work silently; label is just "Your board" / "Spectating Board N".
All verified headless (checkpoint variety + valid paths; 8-board PVP build + phase flips clean; solo + PVE builds clean). Placement/visual fixes still want a real-app eyeball.

**Adjustment pass — 5 user-directed changes (2026-06-01), not committed.** All verified headless (binary at `C:\Users\tobes\Desktop\Godot.exe`); throwaway harnesses deleted.
1. **Campaign maps are now uniformly full-size (40×22).** The per-mission variable grids were dropped — the playfield must never change size between missions. Missions 2–9 (the smaller ones) had their entry/exit/checkpoints/zones/obstacles **proportionally rescaled** corner-to-corner onto the full grid; each mission's tuning (CP/zones/obstacles/supply/rounds/mobs/thresholds) is unchanged. M1/M10 were already 40×22. Verified all 10 load through the real `map_loader` with a valid entry→cp→exit path. `DESIGN_MODES.md` curriculum table + a note updated (this overrode the previously-locked per-mission grids). **NOTE:** supply/thresholds were *not* re-tuned for the bigger boards — same soft/uncalibrated status; may want a pass after playtest (e.g. M2's 35 supply is sparse on 40-wide).
2. **PVP arena minimap (Phase F, first cut).** New `minimap_panel.gd` + `minimap_tile.gd`, created only for multi-board matches (wired in `map_loader` next to `arena_view`). TFT-style 2-column grid of all 8 boards, always on screen. Fog-of-war: own board always clear/live; opponents fogged during build, clear during run. Snapshots captured at each run start (mazes are frozen during run) → during build a seen opponent shows **dimmed remnants under fog**; unseen = solid "?". Towers render as color-modulated cells (kill zones read dark, same as the real board). Click a tile → during run it drives the spectator camera onto the live board (`ArenaView.focus_board()`, new); during build, selecting a seen opponent opens a large fogged "last seen" study panel (click to close). Tab/←→ spectate still works. **Logic verified headless (20/20 checks: tile build, fog flags, snapshot capture + retention, click-select, big-focus visibility, camera focus). Visuals are NOT yet eyeballed — needs a real-app PVP playtest** (headless = dummy renderer).
3. **Pause menu centred.** `_make_centered_panel` used `PRESET_CENTER`, which froze offsets from the panel's pre-content (zero-height) size, leaving it low/off-centre. Now anchored to centre with grow-both — verified the panel centre == viewport centre (960,540).
4. **Pause menu shows objectives.** Campaign & solo/group PVE now list Bronze/Silver/Gold + your current score in the pause menu (reached targets highlighted, others dimmed), refreshed each open. Gated on `gold_threshold > 0`, so PVP (no medals) shows nothing. `DESIGN_MODES.md` pause-menu section noted.
5. **PVE has Daily / Weekly / Monthly windows.** `pve_select.gd` reworked: a tab bar switches between three windows, each with 5 distinct Scale 1–5 maps (15 total). Seeded from the window identity (date / `YYYY-Wnnn` / `YYYY-MM`) plus a per-window salt → verified all 15 seeds unique and 3 distinct score-key dates. Weekly/monthly were always in `DESIGN_MODES`; only daily had been built. Local-only (no backend) as before.


**Playtest logger added (2026-05-31).** `src/scripts/playtest_log.gd` — appends JSON lines to `user://playtest_log.jsonl` (one per completed round + per completed match, local board only): mission/seed/mode, supply, rounds, final + cumulative damage/kills, gold, tower count, medal, thresholds, PVP placement. Wired in `map_loader.build_match`; writes to `user://` only; gated by `ENABLED` (currently true). Verified headless (round + match lines emitted, valid JSON; test cleaned up the file). Purpose: real-score data to calibrate the soft campaign/PVE thresholds. See "NEXT SESSION" above.

**Multiplayer Phase D — PVP ruleset + FIRST PLAYABLE (PVP vs 7 bots) done & verified (2026-05-31), not committed.** The headline mode is now launchable and self-contained (local sim; real netcode is the only thing left for actual multiplayer).
- **Lives/transfers** (`match_coordinator.gd` + `round_manager.gd`): each board starts at `LIVES_PER_PLAYER` (100); `BoardState.kills_this_round` feeds Model B pairwise transfers after every run phase — `net_i = n*kills_i - total_kills` over active boards, zero-sum, no dampening. Boards at ≤0 are eliminated (lives leave the pool), recorded in `finish_order` worst-first; `placement_of(board)` gives 1-based placement (1 = last standing). Coordinator `is_pvp` flag: PVP ends on last-standing (≤1 active) or a `PVP_SAFETY_CAP` (60) stalemate guard — NOT `max_rounds`. Non-PVP keeps the round-count end. New signals `lives_resolved` / `board_eliminated`.
- **Launch**: `SceneManager.start_pvp()` generates a fresh fully-random PVP map (`MapGenerator … Mode.PVP`, no thresholds), sets `pending_board_count = 8` + `current_is_multiplayer = true`, into the match. `pending_board_count` added (1 for solo/campaign/PVE; reset on goto_home). `main.gd` now calls `MapLoader.build_match(self, map, SceneManager.pending_board_count)` instead of `load_into`. `build_match` sets `coordinator.is_pvp` from `map.mode` and inits 100 lives/board for PVP. Home screen **PVP button enabled** → `start_pvp` (was a "coming soon" stub).
- **UI**: HUD shows `Lives: N · alive X/Y` and an uncapped round number in PVP (hidden otherwise). `match_end_panel` rewritten with 3 modes — medal (campaign/PVE, unchanged), **pvp_final** (placement / "Victory!" + Find New Match / Return Home), and **pvp_eliminated** (local board knocked out mid-match → placement + Spectate / Quit to Menu, match keeps running). Pause-menu MP "Quit Match" → home already in place.
- **Verified headless** (throwaway harnesses, deleted): (1) **core sim** — build inits is_pvp+100 lives; one transfer is zero-sum with exact deltas (149/93, pool 800); a board at ≤0 is eliminated with worst placement; driving end-of-rounds resolves to a last-standing winner (placement 1, full 8-deep finish order); campaign build is not pvp. (2) **launch smoke** — the real `main.gd` path builds an 8-board PVP match (is_pvp, 100 lives, HUD present) and 7 bots placed 49 towers during build, no errors. (3) solo path re-smoked clean (exit 0).
- **NOT yet eyeballed in the real app**: an actual PVP match end-to-end (the camera/spectate, HUD lives ticking, transfers/eliminations playing out, result panel) — that's a real-renderer playtest. Also the FX-under-fast-forward early-exit seen in headless could matter more with 8 farming boards — watch memory/stability when playing a real PVP at 2–3x.
- **Remaining (post-first-playable):** LP / rank tiers / season (Phase G meta — placement→LP curve still TBD); difficulty tiers for bots; the full 2-column arena grid (Phase F) vs the current one-board spectate; team/individual PVE group lobby (Phase E). And eventually netcode (Phase H).

**Multiplayer Phase C — baseline bot AI done & verified (2026-05-31), not committed.** Non-local boards now play themselves, so a match has real opponents (solves cold-start).
- `bot_controller.gd` (NEW), one per non-local board, acts only during the build phase, one throttled action per tick (spreads out, reads naturally when spectated). Two behaviours: (1) **maze building** — greedily place the tower that most lengthens the mob path, from a bounded sample (`SAMPLE_K=12`) of placeable cells adjacent to the existing maze/path (seeded from entry/exit/checkpoints on an empty board), up to a round×`difficulty`-scaled target; (2) **upgrading** — once at target / out of useful placements, spend remaining gold upgrading a random tower in a preferred-stat order (damage/attack-speed weighted). `difficulty` field present for later tiers. Stops if `board.is_active()` is false (PVP elimination, Phase D).
- `build_controller.bot_place_tower(cell)` (NEW) — validate + afford + spend + place, same checks as the human input path; the bot drives placement through it.
- Wired in `map_loader._build_board`: each non-local board gets a BotController. (Confirmed projectiles parent under `get_parent()` = the board container, so they render at the right offset — the Phase-B caveat was a non-issue.)
- **Verified headless** (throwaway harness, deleted): a 2-board match (local idle + 1 bot) — the bot placed 9 towers, **lengthened its path** (3249→3396 px), bought 8 upgrade tiers, spent down to 5 gold, and never touched the local board; in the run its towers dealt 382 dmg / 3 kills **only on its own board** (local stayed 0/0 — no cross-board leak). Solo path re-smoked clean (exit 0).
- **Next:** Phase D — PVP ruleset: 100 lives / 800 pool, Model B pairwise lives transfers after each run phase (kill-difference based), elimination at 0, last-standing win + placement, "Find Match" entry that fills with bots. First playable = PVP vs 7 bots — and the first real multi-board launch to eyeball the spectator camera. Difficulty tiers for bots can come alongside.

**Multiplayer Phase B — DONE & verified (2026-05-31), not committed.** N-board lockstep + per-board zone scoping + the spectator camera. Solo is just `num_boards == 1` and renders exactly as before. The coordinator drives N independent boards in lockstep.
- `map_loader.gd` restructured: `build_match(host, map, num_boards)` makes one coordinator + N board containers (each a self-contained sim subtree: own background/zones/markers/obstacles/spawner/build_controller/BoardState + **its own mobs array**). Board 0 is the local player at world origin (so mouse/cell math is exact); extra boards are offset right (`_board_offset`, stride = grid + 6 tiles) — rendering-separation groundwork for the arena view. `load_into(host, map)` stays the solo entry (calls `build_match(…, 1)`). On-screen UI (HUD/panels/pause_menu) binds to board 0 only.
- **Bonus zones scoped per board** (the global-group cross-contamination I flagged in Phase A is fixed): `BoardState.bonus_zones` holds the board's zone nodes; `tower.gd` and `mob.gd` query their own board's zones (via injected `board` ref; `tower.board` set in `build_controller._place_tower` before `_ready`), falling back to the global group only if no board is set. NOTE the zone math is in container-LOCAL coords, so offsetting boards alone would NOT have isolated them — explicit scoping was required.
- `build_controller.interactive` flag: non-local boards get a controller with no input/ghost/upgrade-panel/hint/overlay (process+input disabled), but still `recompute_path()` so their spawner has a wave path.
- **Verified headless** (throwaway harness, deleted): built a 3-board match on mission_04 — all 3 ran in perfect lockstep (identical alive counts), a round advanced ONLY when every board drained to 0 (gate assertion never tripped), each board had its own distinct 3-zone set, and the match ended together at round 3. Separately smoke-tested the solo path (`prototype.tscn` → `load_into`, 150 frames, exit 0, no errors) — no regression.
- **Spectator camera done:** `arena_view.gd` (NEW) — a Camera2D created only when `num_boards > 1` (solo gets none, framing unchanged). Frames ONE board at a time (hides the others to avoid neighbour bleed, centers + zoom-to-fit). Build/post-match → your board only; run phase → cycle every board via Tab / ←→ with a spectate label. Wired in `build_match` (collects board containers). Verified headless: solo has no arena/camera and its board stays visible; multi creates arena+camera, spectate cycles 0→1→2→0 with exactly one board visible, and a build phase snaps back to the local board.
- **Caveat:** the spectate camera's *visual framing* (zoom/centering) is logic-verified only — no real-app multi-board launch exists yet (needs an MP entry point, Phase D, or a debug launch) and headless can't render. Also TODO when bots place towers (Phase C): confirm projectiles parent under the board container so they render at the right offset.
- **Next:** Phase C (bot AI — make the dummy boards actually maze/upgrade/spend) → Phase D (PVP ruleset: lives, pairwise transfers, elimination, last-standing; first playable = PVP vs 7 bots, which also gives the first real multi-board launch to eyeball the camera).

**Multiplayer Phase A — coordinator/board split done & verified (2026-05-31), not committed.** The enabling refactor for local-sim multiplayer (plan: build the full MP experience vs bots in one process, layer netcode on later — networking/hosting still deferred). The match is now **N independent boards + one MatchCoordinator** that owns the shared clock and (later) cross-board resolution. Solo = a coordinator with one board, so the single path serves every mode.
- `match_coordinator.gd` (NEW) — owns round_num/phase/build_timer/max_rounds, the global mob-HP curve, the start-now gate, the run-phase-complete gate (waits for ALL active boards' trains to exit), round advance, match end, and a `_end_round` hook where PVP transfers / PVE aggregation will land. Emits phase_changed/round_changed/build_timer_changed/match_ended.
- `round_manager.gd` slimmed to per-board **BoardState** (kept the filename/`class_name RoundManager` and the `round_manager` var name across consumers to avoid churn — it now means "this board"). Owns gold/economy/damage/kills/spawner/run-detection + lives flag (`eliminated`, for PVP). **Proxies** the clock fields (phase/round/build_time/max_rounds/match_over read from the coordinator) and **forwards** the coordinator's clock signals, so HUD/build_controller/upgrade_panel/panels needed ZERO changes. New methods the coordinator drives: `start_run`/`is_run_done`/`settle_round`/`is_active`.
- `mob.gd` — replaced the `call_group("round_manager", ...)` **broadcast** (which would credit every board) with a direct `mob.board` reference injected by the spawner. `spawner.gd` carries `board` and injects it per mob. `map_loader.gd` builds the coordinator + one board and registers it.
- **Verified headless** (throwaway harness, deleted): a real match built via map_loader ran the full build→run→round-advance→match-end cycle (rounds 1→2→3→ended), gold accrued via settle_round (250→421), and **per-board damage/kill crediting confirmed** (775 dmg / 7 kills to the right board). Used the game's own 3x fast-forward (HUD `_apply_time_scale` re-clamps `Engine.time_scale` every refresh — can't override it externally; FF caps at 3x).
- **Known Phase-B item:** `mob.gd:_current_speed` still queries the global `bonus_zones` group — fine for one board / spatially-separated boards, must be board-scoped when boards coexist.
- **Flagged for a real-renderer check (NOT a refactor regression):** under 3x fast-forward + heavy farming, the headless run exited early (~frame 600) — looks like death/damage-FX accumulation; unverified whether it affects the real renderer (could be a headless dummy-renderer artifact). Possibly related to the earlier run-phase FX churn work.
- **Next:** Phase B — coordinator drives N boards in lockstep (human + idle dummies), spectate-switch to view a board; then Phase C bots, Phase D PVP ruleset (first playable: PVP vs 7 bots).

**Campaign missions 2–10 authored (2026-05-31) — AWAITING PLAYTEST, not yet committed.** The campaign is now content-complete (10/10 missions playable):
- Curriculum locked & recorded in `DESIGN_MODES.md` ("Mission curriculum"). M1 is the big sandbox intro; each later mission isolates one decision on a rising curve; M10 is the capstone bridge to PVE Scale 5. Crit/multishot taught via upgrades (no crit/multishot zones exist — only DAMAGE/ATTACK_SPEED/RANGE/SLOW).
- `mission_02.tres`…`mission_10.tres` hand-authored (same schema/workflow as mission 1). Registered in `scene_manager.gd` `CAMPAIGN_MISSIONS` (all 10). `campaign_select.gd` is data-driven off `has_campaign_mission`, so the "Coming soon" cards auto-flipped to playable — no UI change needed.
- Thresholds derived from mission 1's approved ratio (silver ≈ 1.875 × supply × rounds; bronze ⅔, gold 4⁄3), **soft/uncalibrated** — need playtest calibration like the PVE thresholds.
- **Verified headless** (throwaway harnesses, since deleted): a data harness confirmed all 10 pass field/bounds/threshold checks AND have a valid base path (entry→checkpoints→exit) with obstacles in place and zero towers; a loader smoke test instantiated the real `prototype.tscn` on M8 (12 obstacles) and M10 (6 zones/3 cp/100 supply) and ran 120 frames each with zero errors. Note: `-s` script runs don't init autoloads — used the documented main_scene-swap pattern for the smoke test (see [[reference-godot-headless-verify]]).
- **Next on this track:** playtest 2–10 for feel + threshold calibration, then commit. Then multiplayer (user picked campaign-first; MP approach = "no preference", my recommendation stands: build the full MP experience vs bots in one process first, layer netcode on later — networking/hosting model still deferred).


**Map resource framework built and verified (Claude Code, 2026-05-30).** The mission/map resource architecture from `DESIGN_MODES.md` is now implemented in Godot:
- `GameConstants` autoload holds all global tuning (economy, build timings, mob HP growth, tower base stats, crit/multishot caps, upgrade ramp, lives). Registered in `project.godot`.
- `MapResource` + `ZoneDefinition` resource schemas (`src/resources/`). Per-map values (grid, layout, obstacles, zones, supply, rounds, thresholds) live here.
- `map_loader.gd` builds the live scene from any MapResource; `main.gd` is now a thin host that loads `mission_01.tres` via the loader.
- `mission_01.tres` hand-authored as the first campaign mission — validates the authoring workflow.
- `map_generator.gd` is a **stub** (returns a valid MapResource per the scale table; real procgen + constraint validation still TODO).
- All scripts refactored off hardcoded magic numbers. Verified with a headless run through build phase → run phase → round transition, zero errors.

**Note:** the locked schema stores obstacles as bare cells (`obstacle_cells: Array[Vector2i]`), so the textured multi-tile props (cars, dead trees) from the prototype are gone — each obstacle cell now renders a single debris prop. If richer obstacle visuals matter, the schema needs an `ObstacleDefinition` sub-resource (texture + footprint) — that would reopen the locked MapResource schema.

**UI/navigation Phase 1 done (2026-05-30).** Built the core navigation layer:
- `SaveData` autoload — JSON save at `user://save.json`; holds `first_launch_done` + campaign medals. `SceneManager` autoload — owns transitions, carries the chosen `MapResource` into the match via `pending_map`.
- `boot.tscn`/`boot.gd` — entry point (now `run/main_scene`); first launch sets the flag and drops into mission 1, every launch after opens the home screen.
- `home_screen` (Campaign live; PVE/PVP present but disabled — multiplayer deferred) and `campaign_select` (missions 1–10, all unlocked, best medal per mission; only mission 1 authored, 2–10 shown "Coming soon").
- `main.gd` now reads `SceneManager.pending_map` (falls back to mission 1 if launched directly). Match-end + win-panel exits route through `SceneManager.goto_home()` / `restart_current_match()`; campaign medals persist via `report_match_result`.
- Verified headless: first-launch→mission, returning→home, campaign_select builds, save file writes correctly.

**UI/navigation Phase 2 done (2026-05-30).** Pause menu (`pause_menu.gd`, built by `map_loader`):
- Owns the full Esc priority stack as the single arbiter — `build_controller` no longer handles Esc (exposes `is_build_mode`/`is_upgrade_panel_open`/`close_upgrade_panel`/`exit_build_mode` for the menu to drive). Order: upgrade panel → build mode → pause menu; Esc again resumes.
- SP (campaign / solo PVE) pauses the tree while open; MP does not (reads `SceneManager.current_is_multiplayer`). MP shows "Quit Match" with a context-aware PVP/PVE message; SP shows Restart + Quit to Menu. Both destructive actions go through a confirm dialog.
- Restart → `SceneManager.restart_current_match()`, Quit → `goto_home()`. Settings button present but disabled (Phase 3).
- Verified headless with a throwaway input harness: Esc toggles pause on/off and the quit-confirm dialog appears. Also fixed a real bug found via stderr capture — `boot.gd` called `change_scene_to_file` during `_ready` ("parent busy"); now deferred. See new memory [[reference-godot-headless-verify]].

**UI/navigation Phase 3 done (2026-05-30) — UI layer complete, AWAITING PLAYTEST.** Settings:
- `SaveData` now stores a `settings` dict (master/music/SFX volume, default game speed, fullscreen, resolution index, damage numbers), backfilled from `DEFAULT_SETTINGS` on load, applied at startup. `apply_audio` (guarded by bus existence — no Music/SFX buses yet, so those are inert until audio is added), `apply_display` (DisplayServer fullscreen + windowed resolution).
- `settings_panel.gd` — reusable CanvasLayer overlay (process ALWAYS, layer 40) openable from home screen and pause menu. Sliders/option buttons/checkboxes apply live; saves to disk on close. No own Esc handler — the opener (pause menu in-match, home screen otherwise) closes it on Esc, top of the priority stack.
- Default game speed applied via `Engine.time_scale` at match start (`main.gd`); reset to 1× on menu scenes (`SceneManager`). Damage-numbers toggle gates `mob.gd._spawn_damage_number`.
- Verified headless (stderr captured): boot paths, match+pause+settings build, settings round-trip (set→save→reload→read-back), and the full run phase with the damage-numbers gate. Save reset for a clean first-launch test.

**Committed** `66c5d17` on `main` (playtested & approved, 2026-05-30) — one cohesive commit (phases commingled within shared files, so a clean 4-way split wasn't practical). **Not yet pushed to origin.**

**Procgen done (2026-05-30).** `map_generator.gd` is now a real seeded generator (was a stub):
- Entry/exit on left/right edges; serpentine checkpoints (re-rolled toward a min path-length ratio); obstacles scattered and each validated against the pathfinder (kept clear of edge funnel); bonus zones with the first planted on the path corridor (reachability) and the rest enforcing ≤1 overlap (no 3-way overlap); per-map thresholds derived from path length (soft, tunable). Scale table drives supply/checkpoints/zones/mobs/rounds per tier. PVP omits thresholds.
- Verified via a throwaway harness: 100 maps (tiers 1–5 × 20 seeds) passed every DESIGN_MODES procgen constraint; determinism confirmed; a generated map loads + builds through `map_loader` (same path as campaign). Path/straight ratio avg 1.36.
- **Not yet reachable in-app** — there's no PVE/PVP entry to launch a generated map. The generator is validated infrastructure; wiring a playable PVE-solo entry (map select → generated map → match) is the obvious next step if you want to feel it in the real app.

**Playtest fixes round 2 (2026-05-31) — shipped in commit `8173085`, pushed.** Four more from the second PVE playtest (render fix confirmed in-game by the user):
1. **Partial scores count** — bowing out mid-match now records the current score. `SceneManager.report_match_result(damage)` computes the medal itself; new `leave_match_to_home(damage)` records-then-home, wired into the gold-reached popup (`win_panel`) and the pause-menu quit. Best-kept storage means a partial never beats a full run (the user's no-risk call). Pause SP quit message updated ("Your score so far is saved").
2. **Quit Game from main menu** — `home_screen` bottom-left button → `get_tree().quit()`.
3. **HUD "0/0" at start fixed** — the controller emits `towers_changed` before the HUD is in the tree, so the HUD now seeds count/cap from the controller on connect (shows e.g. `0 / 60`).
4. **Memory/near-crash — root-caused to render-side path overlay.** User confirmed it happened **while hovering in build mode** (no mobs/firing). Measured the hover path headless (dense 80-tower maze, 600 frames of validity + projected-path pathfinding): objects + memory **dead flat at 29.3 MB** — so the pathfinder/logic does NOT leak. Real cause: `build_controller` repainted the whole maze path **every frame** with `draw_line(antialiased=true)` — hundreds of AA segments/frame in the GL-compat renderer, and doubling supply made the maze path much longer, so it spiked. Fixes: **dropped antialiasing** on the dash draw and **throttled the overlay repaint to ~30fps**. Also kept (separate, still worthwhile): `mob.gd`/`death_fx.gd` now share one `SpriteFrames` instead of rebuilding per spawn/death — reduces run-phase churn, though it was NOT the hover cause.
   - **MUST re-verify on the real renderer**: hover in build mode on a dense Scale 4/5 map and watch memory. If it still climbs, the fallback is to replace the immediate-mode `_draw` overlay with a `Line2D` (set points once on path change) instead of redrawing every frame.

All code verified headless (builds clean; HUD cap correct; firing+deaths work with shared frames; partial score records; hover-path memory flat). The render fix itself can't be measured headless (dummy renderer). See [[reference-godot-headless-verify]].

---

**Playtest fixes round 1 (2026-05-31).** Four changes from the first PVE playtest, on top of the PVE-solo work below:
1. **Supply doubled** — PVE scale table now 20/40/60/80/100 (was 10–50); campaign `mission_01` cap 50→100. The 40×22 map was too big to maze with the old supply. (Generated thresholds scale with supply, so they roughly doubled too — still soft.)
2. **Checkpoint count shown** on PVE map cards alongside rounds/supply/zones/mobs.
3. **Upgrade panel clamped on-screen** (`upgrade_panel._position_near`) — flips to the tower's left near the right edge and clamps into the viewport, so towers near any edge no longer hide part of the panel.
4. **Breakpoint-tuned upgrades** — replaced the flat +10%/tier with per-stat increments in GameConstants. Damage `0.34`/tier anchored to base-mob (100 HP) shots-to-kill: tier 1 → 3 shots, tier 3 → 2, tier 9 → 1 (verified via harness). Attack speed `0.15`/tier (extra-shot crossings sooner; placement-dependent). Range stays `0.10`. Crit/multishot unchanged (already discrete/probabilistic).

All verified headless (builds clean; breakpoint table confirmed). Awaiting the user's re-test of feel before commit.

---

**PVE-solo (2026-05-30, shipped in commit `8173085`).** Generated maps are now playable:
- Home `PVE` button enabled → `pve_select` scene: 5 maps (Scale 1–5) seeded from the current date (`hash(window_date) + tier`), so the set is stable per day and changes daily — locally, no backend. Each card shows rounds/supply/zones/mobs + local best score. `SceneManager.start_pve_map` → match (solo = single-player pause variant).
- `SaveData` stores local PVE best scores per `window_date|tier` (`record_pve_score`/`best_pve_score`); `SceneManager.report_match_result` records PVE scores (campaign still records medals).
- Reuses generator + loader + match + pause + settings unchanged. Verified headless: select builds 5 maps, a generated map loads (24 nodes), score round-trips.
- **Caveats:** (1) generated thresholds are very high/uncalibrated (Scale 3 gold ~656k) — fine for PVE since it's high-score-driven and medals are stretch goals, but needs playtest calibration; (2) the campaign-style gold-reached early-win popup is technically still active in PVE but effectively never fires given the high thresholds (leave unless it misbehaves); (3) only the daily window is implemented (weekly/monthly + leaderboards/lobbies remain deferred).

**Next build focus:**
- Threshold calibration once real PVE scores exist (lower `THRESHOLD_COVERAGE` or rework formula).
- Audio bus layout + actual sounds (would make Music/SFX volume sliders live).
- Full PVE (weekly/monthly windows, lobby, leaderboards) and PVP backends — deferred (multiplayer).

---

## UI/Navigation design session — 2026-05-30

Key decisions locked:

### First-launch flow
- Single boolean `first_launch` written to save data on first launch
- First launch: skip home screen, load mission 1 directly
- Player can Esc → Quit to Menu at any time — lands on home screen
- No requirement to complete mission 1; flag is set on launch, not completion
- All subsequent launches go straight to home screen

### Home screen
- Two primary buttons: **PVE** and **PVP**
- Season progress bar + tier badge: slim, top of screen, ambient not dominant
- Campaign: tertiary button, clearly secondary — it's a tutorial, not the product
- Settings: tucked away
- All in-match exits (win modal, pause menu quit) land here

### Campaign navigation
- All 10 missions unlocked from the start — no sequential gating
- Difficulty curve is guidance, not a gate

### PVE navigation
- Solo player: map select → straight into match
- Group: map select → brief lobby (invite + team/individual vote + ready up) → match

### PVP navigation
- One button: Find Match → queued

### Pause menu
- Esc priority stack: upgrade panel → build mode → pause menu
- Single player: pauses tree; options: Resume / Settings / Restart / Quit to Menu
- Multiplayer: does NOT pause tree; options: Resume / Settings / Quit Match
- Restart only available in single player
- Both Restart and Quit to Menu require confirm dialogs
- PVP quit dialog: "You will be eliminated and your lives will leave the pool"
- PVE quit dialog: "Your score will not be posted"
- Settings: master/music/SFX volume, default game speed, fullscreen, resolution, damage numbers toggle

### Specialization removed
- No specialization, no evolution, no milestone effects — ever
- May revisit post-launch if players explicitly request it
- Removed from DESIGN.md; added to anti-goals

---

## Mode design session — 2026-05-30

Full mode design locked. Key decisions: Campaign (solo, 10 missions, tutorial function), PVE (1–4 players, 5 maps per window, scale 1–5, daily/weekly/monthly), PVP (8 players, solo queue, pairwise lives transfers, LP ranking, seasonal resets), Seasons (free battle pass, cosmetic rewards, Masters rank number permanent on cosmetic), MapResource architecture, GameConstants autoload. All in `DESIGN_MODES.md`.

---

## Next step

**For Claude Code:** ✅ The 7-step map-resource framework below is DONE and verified (2026-05-30). Kept here for reference.

1. ✅ `src/resources/game_constants.gd` — autoload singleton, all global magic numbers moved in
2. ✅ `src/resources/map_resource.gd` — MapResource schema (note: `Window` enum renamed `WindowType` — shadowed native class; `bonus_zones` left untyped to dodge the cross-script typed-array pitfall)
3. ✅ `src/resources/zone_definition.gd` — ZoneDefinition sub-resource
4. ✅ `src/scripts/map_loader.gd` — reads MapResource, builds scene
5. ✅ `main.gd` — thin host, loads `mission_01.tres` via loader
6. ✅ `src/campaign/mission_01.tres` — first campaign mission, hand-authored
7. ✅ `src/scripts/map_generator.gd` — stub (real procgen TODO)

Next candidates (pick one): real procgen in `map_generator.gd` per the "Procgen constraints" spec; or the home-screen / mode-select scene so `main.gd` stops hardcoding mission 1.

**For this Claude (design):**

- Leaderboard backend design (captured in `notes/leaderboards.md` — needs updating with mode decisions)
- PVP LP curve (exact points per placement TBD)
- Season pass point values and milestone thresholds
- Damage threshold calibration (needs real playtest data)
- Soft caps for damage / range / attack_speed upgrade stats

---

## Recently touched files

- `src/resources/game_constants.gd` — NEW autoload, all global tuning
- `src/resources/map_resource.gd`, `zone_definition.gd` — NEW resource schemas
- `src/scripts/map_loader.gd`, `map_generator.gd` — NEW (generator is a stub)
- `src/scripts/main.gd` — gutted to a thin loader host
- `src/scripts/round_manager.gd`, `tower.gd`, `mob.gd`, `build_controller.gd`, `hud.gd`, `match_end_panel.gd`, `win_panel.gd` — refactored off magic numbers / old consts
- `src/campaign/mission_01.tres` — NEW first mission
- `src/scripts/save_data.gd`, `scene_manager.gd`, `boot.gd`, `home_screen.gd`, `campaign_select.gd` — NEW (UI/nav Phase 1)
- `src/scenes/boot.tscn`, `home_screen.tscn`, `campaign_select.tscn` — NEW screens
- `src/scripts/main.gd` — reads SceneManager.pending_map; `win_panel.gd`/`match_end_panel.gd` route exits home
- `src/scripts/pause_menu.gd` — NEW (UI/nav Phase 2); `build_controller.gd` — Esc handling removed, public hooks added; `boot.gd` — deferred routing; `map_loader.gd` — instantiates pause menu
- `src/scripts/settings_panel.gd` — NEW (UI/nav Phase 3); `save_data.gd` — settings storage + apply; `home_screen.gd`/`pause_menu.gd` — Settings button + Esc-close wired; `main.gd`/`scene_manager.gd` — game-speed time_scale; `mob.gd` — damage-numbers gate
- `src/project.godot` — GameConstants + SaveData + SceneManager autoloads; main scene now boot.tscn
- `STATE.md` — this file

---

## Open questions / blocked on

### Implementation (Claude Code)
- Procgen algorithm for PVE/PVP map generation — constraints specced in DESIGN_MODES.md, algorithm TBD
- Bot behavior in PVP private lobbies — deferred
- Eliminated player maze handling in PVP — deferred
- Networking/hosting model — deferred
- Home screen scene implementation — design locked, implementation not started
- Pause menu scene implementation — design locked, implementation not started
- First-launch flag system — design locked, implementation not started

### Design (this Claude)
- Leaderboard backend design
- PVP LP curve
- Season pass point values and milestone thresholds
- Damage threshold calibration — needs playtest data
- Soft caps for damage / range / attack_speed

### Locked design decisions
See `DESIGN.md` and `DESIGN_MODES.md`.
