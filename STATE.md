# State

Last updated: 2026-05-30

---

## Current focus

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

**NOT COMMITTED.** Per the user: wrap/commit only after they playtest and approve. Suggested commits when approved: (1) resource framework, (2) navigation layer, (3) pause menu, (4) settings.

**Next build focus (after playtest):**
- Real procgen in `map_generator.gd` (still a stub) per the "Procgen constraints" spec.
- Audio bus layout + actual sounds (would make Music/SFX volume sliders live).
- PVE/PVP backends (deferred — multiplayer).

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
