# State

Last updated: 2026-05-30

---

## Current focus

**Playable SP loop + first playtest tweak pass done.** On top of the complete maze-building loop (6 upgrade stats, 4-type bonus zones, build/run rounds, gold economy, supply cap, Bronze/Silver/Gold thresholds, match-end modal), this session added: single-player fast-forward, off-screen entry/exit, non-stop death FX, scattered environment obstacles, per-tower damage/kill tracking, a win-on-Gold modal, effective-stat readouts in the upgrade panel, and a round-end gold-breakdown toast — plus fixed a hard crash in the placement path. **Next build focus: the mission/level framework + level-select (home) screen, then author the first campaign levels.** Two design items parked for dedicated chats: leaderboards ([notes/leaderboards.md](notes/leaderboards.md)) and the pause menu (plan below).

---

## Playtest tweak pass + crash fix + UX — 2026-05-30

Long session: playtest-driven tweaks, a real crash fix, environment obstacles, and a batch of readability/UX features. STATE was intentionally not updated mid-session at the user's request.

### Gameplay tweaks
- **Fast-forward (SP)** ([hud.gd](src/scripts/hud.gd)) — "Speed: Nx" button cycles 1x→2x→3x→1x via `Engine.time_scale`. Applies during the **run** phase only; build + post-match forced to 1x so it can't drain the build timer. Reapplied on each `phase_changed`.
- **Entry/exit off-screen** ([build_controller.gd](src/scripts/build_controller.gd), [main.gd](src/scripts/main.gd)) — flags removed; `current_path_world()` prepends/appends an off-screen point (`OFFSCREEN_PAD = 160px`) so mobs spawn/despawn beyond the map edge. Reserved funnel cells (col 0 / 39) kept so towers can't plug the mouth.
- **Tower cost 20g → 10g** ([round_manager.gd](src/scripts/round_manager.gd)).
- **Mobs never stop on death** ([mob.gd](src/scripts/mob.gd), new [death_fx.gd](src/scripts/death_fx.gd), [tower.gd](src/scripts/tower.gd)) — removed the `state`/"die" freeze. On kill, mob spawns a self-freeing `DeathFx` burst and instantly resets HP, marching without pause. Towers' `_find_targets` dropped the defunct `m.state` filter.

### Environment obstacles (item #4 from the tweak list — DONE)
- New [obstacle.gd](src/scripts/obstacle.gd) — a prop claiming a footprint of grid cells, fed into the build controller's `blocked` map so it acts as a permanent wall (A* routes around, towers can't place on it). Auto-fits the sprite to its footprint.
- Art comes from the new `art/environment_art/props/` pack (post-apocalyptic urban set). 8 props copied into `src/assets/environment/props/` and hand-scattered on the test map via `OBSTACLES` in [main.gd](src/scripts/main.gd): wrecked cars, toppled truck, dead trees, rubble piles, oil drum. Placed clear of the funnel/checkpoints/zone centers so they add detours without sealing a route.
- MP will randomize these later; campaign hand-places them.

### CRASH FIX — placement-path SIGSEGV
- **Symptom:** silent crash (signal 11) while hovering/placing towers, no debugger output. Found via Godot's log at `%APPDATA%/Godot/app_userdata/Maze Battle TD/logs/godot.log`.
- **Root cause:** the A*+string-pull path was essentially never exercised until obstacles forced detours. `_process` ran **two full multi-segment pathfinds every frame** while hovering a valid cell (`_is_valid_placement` + `_compute_projected`), now each doing A*+string-pull ~120×/sec near obstacles — the allocation churn crashed the engine (crash landed on a benign `blocked.has()` in the hot loop).
- **Fix** ([build_controller.gd](src/scripts/build_controller.gd)) — cache ghost validity + projected path; recompute **only when the hovered cell changes** (or the maze changes / build mode reopens, which invalidate via `_last_ghost_cell = _NO_CELL`). Pathfinder logic itself was correct and left untouched. Confirmed fixed by the user.

### Readability / UX batch (items #2 + #4)
- **Per-tower damage + kills** ([tower.gd](src/scripts/tower.gd), [projectile.gd](src/scripts/projectile.gd), [mob.gd](src/scripts/mob.gd)) — tower stamps itself on each projectile → `mob.take_hit(dmg, is_crit, source)` credits the source tower via `register_damage(amount, killed)` (overkill-clamped, matches score). Upgrade panel shows `Damage done / Kills`, live-updating while open → lets you spot your top-DPS tower.
- **Effective stats in upgrade panel** ([upgrade_panel.gd](src/scripts/upgrade_panel.gd)) — each stat row now shows its real value incl. zone bonuses: Damage (number), Range (tiles), Atk Speed (hits/sec), Crit (%), Crit Dmg (×mult), Multishot (target count).
- **Round-end gold toast** (new [round_toast.gd](src/scripts/round_toast.gd)) — top-center popup: `Round N complete +Xg kills · +Yg round bonus · +Zg interest`, fades after 2.5s. Driven by new `round_summary` signal; round-kill gold tracked via `_round_kill_gold`.

### Win-on-Gold (item #3 — DONE)
- New `gold_goal_reached` signal fires the first time total damage crosses `GOLD_DAMAGE` mid-match.
- New [win_panel.gd](src/scripts/win_panel.gd) — pauses the tree (`PROCESS_MODE_ALWAYS`) and shows "GOLD REACHED — You won!" with **Keep Playing** (unpause) / **Return Home** (restart). Fires once per match.
- **Known gap:** "Return Home" (and the win modal generally) has no real home screen yet — currently just reloads the level. Also: after *Keep Playing* there's no way to leave the match until round 10 — this is what the planned pause menu fixes.

### Parked for dedicated chats
- **Leaderboards** — captured in [notes/leaderboards.md](notes/leaderboards.md). 9 boards: Solo/Duo/Trio/Quad each × {with-bots, without-bots} = 8, plus all-8 humans-only (no groups, no bots). Score model for grouped formats TBD.
- **Pause menu** (plan, not built) — Esc-triggered, pauses tree like win_panel. Items: Resume / Settings / Restart Level / Quit to Menu. **Key conflict:** Esc is currently consumed by build_controller (exit build → close upgrade panel) — needs a priority order or a dedicated key. **Dependency:** "Quit to Menu" + win modal's "Return Home" both need a main-menu scene that doesn't exist yet. Settings contents to spec: volumes, default game speed, fullscreen/resolution, maybe damage-number toggle.

### Files
- New: `death_fx.gd`, `obstacle.gd`, `win_panel.gd`, `round_toast.gd`, `notes/leaderboards.md`, `src/assets/environment/props/*` (8 PNGs).
- Modified: `hud.gd`, `build_controller.gd`, `main.gd`, `round_manager.gd`, `mob.gd`, `tower.gd`, `projectile.gd`, `upgrade_panel.gd`.

### Still pending from earlier playtest note
- Damage numbers / thresholds calibration: user noted top-score damage is currently too low vs. thresholds — OK for now, real tuning still pending.

---

## Match-end loop, score HUD, supply cap, polish — 2026-05-28

Closed the prototype's "no ending" gap and pulled the UI up to read at a glance. Multiple small playtest-iteration cycles in one stretch.

What landed:

- **Zone labels** ([bonus_zone.gd](src/scripts/bonus_zone.gd)) — each zone displays its type + magnitude in the center (e.g. `DAMAGE +20%`, `ATK SPEED +70%`, `RANGE +30%`, `SLOW -40%`). White text, black outline, 18pt. Color is the indicator; text is the description.
- **Zone size rescale** — formula now `r_tiles = max(0.75, 4.0 - (mag-10)/30)`. 10% → 4 tiles (max), 100% → 1 tile (min). Linear inverse. MVP zone magnitudes spread out to show visible size variety (20/70/30/40 vs prior 30/40/30/30).
- **Floating damage numbers** ([damage_number.gd](src/scripts/damage_number.gd)) — spawn 36px above mob on hit, rise 64px over 1.5s, opaque first 60% then fade. Normal hits: 16pt white. Crits: 24pt gold with `!`. Plumbed `is_crit` through projectile → `mob.take_hit(damage, is_crit)`. **Gotcha fixed**: `_start_y` was being captured in `_ready` (before setup moved the node) — moved capture into `setup()` itself.
- **Start Round button** in HUD ([hud.gd](src/scripts/hud.gd)) — visible during build phase, hidden during run + after match end. Calls `round_manager.request_start_now()` which skips the remaining build timer. MP gating ("everyone presses") flagged as TBD in code comment.
- **Dash-flow direction fix** in [build_controller.gd](src/scripts/build_controller.gd) — flipped sign on `dash_g_start` so the animated path flows from entry toward exit (matches mob travel).
- **Match-end loop** — [round_manager.gd](src/scripts/round_manager.gd) now caps the match at `MAX_ROUNDS = 10`. `_end_round()` checks after awarding round bonus + interest; if at cap, calls `_end_match()` which sets `match_over = true` and emits `match_ended`. `_process` early-returns when over so timers freeze.
- **Score = total damage dealt** — `total_damage_dealt` accumulated via `_on_damage_dealt(amount)` group-dispatched from `mob.take_hit`. Overkill is clamped at the call site (a 100-dmg shot on a 10-HP mob credits 10).
- **Bronze / Silver / Gold thresholds** — `BRONZE_DAMAGE = 1250`, `SILVER = 1875`, `GOLD = 2500`. Derived from user's "1 base shot per tower per round" formula × 5 towers × 10 rounds × {1, 1.5, 2}. Working — playtest will tell us if they're trivial or punishing.
- **Match-end modal** ([match_end_panel.gd](src/scripts/match_end_panel.gd)) — center-anchored panel triggered by `match_ended` signal. Shows medal label (gold/silver/bronze/none), total damage + rounds, three threshold rows with ●/○ achievement markers, "New Game" button that calls `get_tree().reload_current_scene()` for a clean reset.
- **HUD additions** ([hud.gd](src/scripts/hud.gd)) — `Round X / 10`, `Gold`, `Score`, `Kills`, `Towers: X / 50`, phase + build timer. New signals: `kills_changed` (round_manager), `towers_changed(count, cap)` (build_controller). HUD now also holds a `build_controller` reference.
- **Supply cap = 50** — `MAX_TOWERS` const in [main.gd](src/scripts/main.gd) (per DESIGN: map variable). Passed to `build_controller.max_towers`. Placement validation rejects when at cap.
- **Tower cost drop** — `TOWER_COST` 50g → 20g. Starting 250g now places 12 towers cleanly with room for upgrades.

Files: new `src/scripts/damage_number.gd`, `src/scripts/match_end_panel.gd`; modified `src/scripts/round_manager.gd`, `src/scripts/hud.gd`, `src/scripts/build_controller.gd`, `src/scripts/bonus_zone.gd`, `src/scripts/main.gd`, `src/scripts/mob.gd`, `src/scripts/projectile.gd`.

---

## Bonus zones MVP — 2026-05-28

Implemented the four-type bonus-zone MVP per DESIGN (with caveat: full type set + color assignments were flagged TBD in STATE; user chose all-four for MVP, stat-color mapping for the three buff zones, working cyan for slow). Folded in the dash-flow direction fix from prior playtest.

What landed:

- **[bonus_zone.gd](src/scripts/bonus_zone.gd)** (new) — Node2D rendering a filled circle with outline via `_draw`. Fields: `type`, `magnitude` (10-100 stepped), `radius` (px). API: `touches_tower_cell(cell)` (DESIGN's footprint-touch: distance ≤ radius + half-tile), `contains_world(pt)` for mob slow check, `radius_for_magnitude(mag)` static helper. Joins `bonus_zones` group on `_ready` so anything in the scene can find zones via `get_tree().get_nodes_in_group("bonus_zones")`.
- **Working magnitude→radius formula**: `r_tiles = max(1, 6 - mag/20)`. Linear inverse hitting DESIGN's two example points (10%→r=5 tiles, 100%→r=1 tile). Exact curve still TBD.
- **Working colors**: damage=red, attack_speed=blue, range=green, slow=cyan (DESIGN-locked colors for the first three via tower-stat coherence; slow has no tower-stat equivalent, cyan is a working pick).
- **Hand-placed zones in [main.gd](src/scripts/main.gd)**: damage 30% at (18,5), attack_speed 40% at (14,12), range 30% at (26,16), slow 30% at (22,9) — slow straddles the cp1→cp2 sweep so mobs walk through it.
- **[tower.gd](src/scripts/tower.gd)**: cached `zone_bonus = {damage, range, attack_speed}` populated in `_ready` via group lookup. `get_damage`/`get_range`/`get_cooldown` add zone% to tier% additively (per DESIGN: zone bonuses stack additively for same type; cross-stat layering is a working assumption since DESIGN doesn't lock tier×zone vs tier+zone). Range circle refreshes after zone bonus applied.
- **[mob.gd](src/scripts/mob.gd)**: `_current_speed()` sums slow-zone magnitudes containing the mob's current position, applies multiplier with 10% speed floor. Called every `_physics_process` (cheap — few zones).
- **Build-controller dash direction**: flipped sign on `dash_g_start` so dashes flow from entry toward exit, matching mob travel direction.

Visual stacking works for free: same-color zones overlapping add alpha and read as deeper saturation; different colors blend naturally — DESIGN's "red zone + red tower = obvious doubling-down" reads correctly.

Files: new `src/scripts/bonus_zone.gd`; modified `src/scripts/main.gd`, `src/scripts/tower.gd`, `src/scripts/mob.gd`, `src/scripts/build_controller.gd`.

---

## Path rework — 2026-05-28 (direct lines + tower-only detours, animated overlay)

User flagged that the previous grid-A*-everywhere pathing was still wrong: with zero towers placed, mobs should walk in straight lines entry → cp1 → cp2 → cp3 → exit. Detours only when a tower's footprint actually crosses a straight segment. Also: path overlay should be a flowing blue indicator, not a static yellow line.

What changed:

- **[pathfinder.gd](src/scripts/pathfinder.gd) rewritten** — new public API `compute_full_path(start, waypoints, goal, blocked) -> PackedVector2Array` returns world-space polyline directly. Per segment: try direct line first (sample 6px steps, check blocked-cell hits); only if blocked, fall back to 8-directional A* (no corner-cutting through diagonally-adjacent towers, octile heuristic) then string-pull the result so the polyline only bends where geometry forces it.
- **[build_controller.gd](src/scripts/build_controller.gd)** — dropped both Line2D path nodes. Path is now rendered in `_draw()` as flowing dashed blue line (22px dashes, 14px gaps, 70px/sec scroll, clipped at polyline vertices so corners render correctly). When a ghost tower is on a valid cell during build mode, the projected post-placement path is rendered in lighter cyan instead.
- Node z_index = -10 so the overlay sits under towers/mobs (z=0) but over background/markers (z=-40, -100).
- Spawner/mob unchanged — they already consume the world-space polyline from `current_path_world()`.

---

## Pivot — 2026-05-28 (maze-building, grid + A*)

User flagged that the prior round's "multiple checkpoints in path" implementation was building a standard fixed-path TD, which is **not** what DESIGN specifies. Re-read DESIGN.md: the game is a maze-builder. Mobs path dynamically through entry → cp1 → cp2 → cp3 → exit using A* against a grid where towers are walls. Tower placement is free anywhere except (a) on entry/exit/checkpoint cells, (b) on another tower, (c) if placing would fully block any segment of the chained path. The Line2D "path" I added previously was conceptually wrong.

What landed in the pivot:

- **Grid system** (new [grid.gd](src/scripts/grid.gd)) — 40×22 tiles @ 48px, helpers `cell_to_world` / `world_to_cell` / `in_bounds`.
- **A* pathfinder** (new [pathfinder.gd](src/scripts/pathfinder.gd)) — 4-connected orthogonal A* with Manhattan heuristic. `find_chained_path(start, waypoints, goal, blocked)` walks segment-by-segment and concatenates.
- **Maze cells** in [main.gd](src/scripts/main.gd) — `ENTRY_CELL=(0,11)`, `EXIT_CELL=(39,11)`, checkpoints at `(35,3)`, `(4,18)`, `(35,18)` — long zig-zag forcing mobs to traverse most of the map. Markers: green flag (entry), red flag (exit), yellow buttons (checkpoints). Visible fixed-path Line2Ds removed.
- **Build controller rewrite** ([build_controller.gd](src/scripts/build_controller.gd)):
  - Ghost snaps to grid cell at mouse position
  - `_is_valid_placement(cell)`: in-bounds, not blocked, not a reserved (entry/exit/checkpoint) cell, AND a simulated A* with this cell added still resolves all chain segments
  - Owns `blocked: Dictionary[Vector2i]` updated on place + sell
  - `recompute_path()` runs A* against current blocked set; cached in `_current_path_cells`
  - Always-on `_path_line` shows the current canonical path; in build mode, hovering a valid ghost cell additionally renders `_projected_line` showing the path that would result if placed
  - Exposes `current_path_world() -> PackedVector2Array` for the spawner to consume at run-start
- **Spawner** ([spawner.gd](src/scripts/spawner.gd)) — `start_wave(count, interval, hp, wave_path)` now takes the path per wave; round_manager pulls `build_controller.current_path_world()` when starting the run phase.
- **Visual sizing** — tower sprite scale 0.25 → 0.12, mob scale 0.13 → 0.08, tower base range 320 → 160 (≈3.3 tiles). All to fit the smaller 48px tile grid.
- **Construction-order fix** in main.gd — instantiate all nodes, set cross-refs, then `add_child` each. Previously build_controller's `_ready` ran before round_manager existed, so its signal hookups silently failed.
- **Memory updated** ([reference_godot_classname_cycle](../../Users/tobes/.claude/projects/C--dev-Maze-Battle-TD/memory/reference_godot_classname_cycle.md)) — broadened the rule to "always preload + alias for cross-script class refs; treat `class_name` global identifiers as unreliable across script boundaries."

Files produced/modified in pivot:

- New: `src/scripts/grid.gd`, `src/scripts/pathfinder.gd`
- Rewritten: `src/scripts/build_controller.gd`, `src/scripts/spawner.gd`, `src/scripts/main.gd`
- Modified: `src/scripts/tower.gd` (scale + range), `src/scripts/mob.gd` (scale), `src/scripts/round_manager.gd` (build_controller ref)

---

## Earlier this session — 2026-05-28 (upgrade mechanics + rounds + path)

Implemented the four queued next-step items from the prototype kickoff session, in order.

**1. Crit + multishot wired in tower** ([tower.gd](src/scripts/tower.gd), [projectile.gd](src/scripts/projectile.gd))
- Crit chance: per-shot `randf()` roll, +10%/tier, hard cap 75%.
- Crit damage: base 1.5×, +20%/tier (cap TBD).
- Multishot: fires `1 + tier` projectiles, each at a different mob ordered by `path_index` descending. Hard cap +3 additional targets (4 total).
- Crit projectiles render larger (0.75× vs 0.5×) and gold-tinted.
- New tower methods: `get_crit_chance()`, `get_crit_damage_mult()`, `get_multishot()`, `_find_targets(count)`.

**2. Round structure + gold economy** (new [round_manager.gd](src/scripts/round_manager.gd), new [hud.gd](src/scripts/hud.gd), updates to [spawner.gd](src/scripts/spawner.gd), [mob.gd](src/scripts/mob.gd), [build_controller.gd](src/scripts/build_controller.gd), [upgrade_panel.gd](src/scripts/upgrade_panel.gd), [tower.gd](src/scripts/tower.gd), [main.gd](src/scripts/main.gd))
- Build/run phase state machine. Build phase auto-advances on timer expiry. Run phase ends when all mobs in train have exited.
- Build phase timing: 30s round 1, 25s rounds 2–29, 8s round 30+ (DESIGN-locked).
- Gold income: 1g per mob explosion + (25 + round#) round bonus + 10% interest cap 50/round (DESIGN-locked interest).
- Tower placement: 50g. Starting gold 250g (player can place 5 towers cleanly, or fewer with upgrades).
- Upgrade tier costs: linear ramp, per-stat scaling — damage 15·t, range 20·t, atk_speed 20·t, crit_chance 25·t, crit_damage 25·t, multishot 60·t (where t is tier-after).
- Sell refund: 30% of total invested (DESIGN-locked). `tower.total_invested` accumulates placement cost + each tier cost paid.
- Build mode and upgrade buttons gate to build phase. Upgrade panel buttons show live cost and disable when unaffordable or in run phase.
- Mob HP scales: flat first 5 rounds, then ×1.12/round (working assumption).
- Spawner refactored: no longer auto-spawns on `_ready`; `start_wave(count, interval, hp)` driven by round_manager. Spawner exposes `is_done()`.
- HUD canvas-layer in top-right shows Round, Gold, Phase + build-timer countdown.
- Kill-bonus wiring: mob calls `get_tree().call_group("round_manager", "_on_mob_killed")` on explosion; round_manager registers itself in the `round_manager` group.

**3. Background tiled with grass** ([main.gd:_setup_background](src/scripts/main.gd))
- Replaced flat `ColorRect` mid-green with `TextureRect` tiling `summer_grass_tile.png` (stretch_mode = STRETCH_TILE).
- Path tilesheet (`summer_grass_path.png`) is irregular path pieces, not a uniform grid — would need grid-snapped placement to use cleanly. Deferred until placement is grid-snapped.
- Path now rendered as two stacked `Line2D`s: darker yellow-green edge (64px) + sandy yellow body (54px) to read against grass.

**4. Multiple checkpoints in path** ([main.gd](src/scripts/main.gd))
- Path extended from 3 points to 6 — right-angle Z-shape (entry → cp1 → cp2 → cp3 → bend → exit).
- `CHECKPOINT_INDICES = [1, 2, 3]` drives marker placement. Each checkpoint gets a `level_marker_01` sprite.

**Gotcha discovered + saved as memory** ([reference_godot_classname_cycle](C:/Users/tobes/.claude/projects/C--dev-Maze-Battle-TD/memory/reference_godot_classname_cycle.md))
- GDScript `class_name` typed cross-references between scripts that inject each other fail at parse time with "Could not resolve external class member" / "Identifier X not declared in current scope." Workaround: untype the injected ref, preload the script to access constants.

Files produced/modified this session:

- New: `src/scripts/round_manager.gd`, `src/scripts/hud.gd`
- Modified: `src/scripts/tower.gd`, `src/scripts/projectile.gd`, `src/scripts/mob.gd`, `src/scripts/spawner.gd`, `src/scripts/build_controller.gd`, `src/scripts/upgrade_panel.gd`, `src/scripts/main.gd`
- Updated: `STATE.md` (this file)

---

## Next step

Pick on next session start:

1. **Playtest pass + threshold tune** (recommended) — actually play 5-10 matches, calibrate Bronze/Silver/Gold thresholds (current 1250/1875/2500 are educated guesses), check gold flow vs upgrade costs, verify HP curve doesn't melt or wall, see if supply cap 50 feels reachable, check zone magnitudes. Update numbers in code, note in STATE if anything wants a real design conversation.
2. **HP bars on mobs** — small bar above each mob showing HP fraction. Pure readability win for both playtest and live play. No design surface.
3. **Upgrade panel shows effective stats** — display real damage / range / atk-speed numbers including zone bonuses, not just tier counts. Helps the player see what they're paying for.
4. **Round-end summary toast** — short on-screen popup at round end showing the gold breakdown ("Round 3 complete · +28g round bonus · +12g interest"). Reinforces the economy.
5. **Mission framework + a second map** — start moving the hardcoded map config (cells, zones, thresholds, supply cap, round count) into a mission resource. Enables building a real campaign.

Recommended order: 1 → 2 → 3 → 4 → 5. Tune before adding more systems. Don't propose anything in "Open questions" flagged as placeholder/TBD without locking the design first ([memory note](../../Users/tobes/.claude/projects/C--dev-Maze-Battle-TD/memory/feedback_no_placeholder_features.md)).

---

## Recently touched files

See "Files produced/modified this session" above.

---

## Open questions / blocked on

Carried over; many closed this session (struck through).

### Upgrade mechanics
- ~~Multishot — hard cap 2–3 TBD~~ → set to **+3 additional** (4 total), working.
- ~~Crit chance — soft cap 75% TBD~~ → set to **75% hard cap**, working.
- ~~Crit damage — soft cap 500% TBD~~ → uncapped for now (base 1.5× + 0.20/tier).
- ~~Tier costs — currently free~~ → wired: linear per-stat ramp.
- Soft caps for damage / range / attack_speed — none yet, may want them.
- Specialization milestones (heavy shot, sniper, frenzy, lucky streak, devastator, spread) — placeholder, need real design.
- Specialization trigger threshold (working: ~level 15 cumulative).

### Bonus zones (untouched)
- Magnitude/size interpolation curve (linear vs non-linear, exact floor/ceiling values per type)
- Full type set beyond damage and slow — attack speed, crit, multishot, range (set of 6 implied)
- Color assignments per zone type
- Map procgen reachability constraint algorithm
- Maximum zone count per map (working: 5–6)
- Map grid dimensions for MP (working: ~30×30 to 40×40)

### Wave structure
- ~~HP scaling curve shape~~ → working: flat 1–5, ×1.12/round after. Needs playtest.
- ~~Build phase timer~~ → wired to DESIGN values.
- Mob train length per map (Enemy Supply — working 8 mobs).

### Bonus zones — closed since last session
- ~~Color assignments per zone type~~ → working: matched to tower stat colors; slow = cyan.
- ~~Magnitude/size interpolation curve~~ → working: `r_tiles = max(0.75, 4 - (mag-10)/30)`. Linear inverse.
- ~~Full type set~~ → MVP shipped with all four (damage, atk_speed, range, slow). Crit/multishot zones available to add when desired.

### Score / match end — closed since last session
- ~~Win condition for SP~~ → total damage dealt, three thresholds per level.
- ~~Bronze/Silver/Gold thresholds methodology~~ → working: `base_dmg × supply × rounds × {1, 1.5, 2}` formula. Per-level values are playtest-tuned.
- ~~Soft-cap structure~~ → hard cap at MAX_ROUNDS per level. Level 1 = 10 rounds.
- ~~Supply cap~~ → per-map variable. Level 1 = 50.
- Mission count + per-mission threshold/supply/round-cap values — still open; need mission framework.

### Multiplayer / Campaign / Bots / Guilds / Platform & art / Risks
Unchanged from prior STATE — see git history for prior content.

---

## Reference: locked design decisions

See `DESIGN.md` for the full locked design. Decisions there don't get re-litigated without explicit reopening.
