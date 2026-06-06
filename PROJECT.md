# Project Map — Wend

One-line index of what exists in this project. Read at start of every session for orientation.

(**Wend** is the game's name — locked 2026-06-05. Modes: Trials = PVE, Ranked = PVP.)

---

## Repo root files

- `claude-rules.md` — Universal Claude rules (mirror of master copy)
- `RULES.md` — Project-specific addendum to claude-rules
- `STATE.md` — Current focus, last session, next step, open questions
- `STATE_ARCHIVE.md` — Older session logs, moved out of STATE to keep it small (reference only)
- `PROJECT.md` — This file. Map of what exists.
- `.gitignore` — Ignores `art/` (third-party asset pack source), dev artifacts, OS junk

## Directories

- `design/` — Locked design docs:
  - `DESIGN.md` — core game design decisions
  - `DESIGN_MODES.md` — modes, maps, progression, seasons, UI, map-resource architecture
  - `VISUAL_SYSTEM.md` — canonical visual language (palette, type, icons), menu + PVP UI specs
  - `INMATCH_FIXES.md` — scoped Claude Code in-match tasks (obstacle schema, movement chevron)
- `notes/` — Working notes, backlog, market research, references:
  - `open_items.md` — **backlog ledger; start here for what's open / what's resolved**
  - `pvp_ladder.md` — Ranked LP/MMR/tier/season spec
  - `leaderboards.md` — board set, group scoring, frontend placement (Nakama)
  - `season_pass.md` — season pass structure / point values
  - `pvp_lobby.md` — PVP lobby notes
  - `meta_structure.md` — early meta/campaign shape draft (v0; partly superseded)
  - `multiplayer_architecture.md` — netcode + hosting architecture + cost model
  - `server_decision.md` — dedicated-server / anti-cheat direction
  - `remote_beta_plan.md` — Hetzner VPS + Google Play Internal Testing beta plan
  - `gtm.md` — go-to-market / Steam page / community notes
  - `mockups/` — HTML UI mockups (in-match layout, full-size board, juice taste)
  - `video_frames/` / `screenshots/` — debug frame extracts + reference shots (gitignored)
- `src/` — Godot 4 project (open `src/project.godot` in Godot). Contains `scenes/`, `scripts/`, `resources/`, `campaign/`, `assets/`, `net/`, and its own `.gitignore` for the `.godot/` cache.
- `src/scenes/` — `boot.tscn` is the main scene (first-launch routing). `prototype.tscn` is the match scene host (`main.gd`, a thin loader that hands a `MapResource` to `map_loader`).
- `src/scripts/` — Gameplay + UI scripts (`main`, `mob`, `tower`, `projectile`, `spawner`, `build_controller`, `round_manager`, `match_coordinator`, `hud`, `action_strip`, `tower_drawer`, `pathfinder`, `road_renderer`, `bonus_zone`, `obstacle`, `map_loader`, `map_generator`, UI/nav scripts, `playtest_log`, etc.).
- `src/net/` — Multiplayer transport + match netcode (`net_protocol`, `match_transport`, `local_transport`, `enet_transport`, `net_match`, `match_server`).
- `src/resources/` — `game_constants.gd` (GameConstants autoload — all global tuning), `map_resource.gd` + `zone_definition.gd` + `obstacle_definition.gd` + `obstacle_props.gd` (map/obstacle schema), shared by all modes.
- `src/campaign/` — Hand-authored campaign mission `.tres` files (`mission_01.tres` … `mission_10.tres`).
- `src/assets/` — Curated subset of the asset pack actually used by the project (tower sprites, zombie animations, map tiles, level markers, `ui/icons/` — currently a 15-icon subset). Committed.
- `art/` — Full third-party asset pack (`art.zip` source-of-truth) for what we pull into `src/assets/`. **Gitignored** for license safety.
- `levels/` — Legacy/unused; campaign mission definitions live in `src/campaign/` as `.tres` files.

## External references

- GitHub repo: https://github.com/TobeSullivan/tower_defense (public)
- Reference game: **Random TD** (StarCraft 2 custom map, Hive Workshop archive)
- Cautionary reference: **AMazing TD** (Steam, by Go4 Games — same team as Random TD)
- Godot binary: `C:\Users\tobes\Desktop\Godot.exe` (4.6.3 stable, not on PATH; reference by full path in commands)
- Python toolchain: `C:\Users\tobes\AppData\Local\Programs\Python\Python312\python.exe` with Pillow, numpy, scipy, imageio, imageio-ffmpeg installed (used for asset-pack inspection and video frame extraction)

---

## Reading order at session start

1. `claude-rules.md`
2. `RULES.md`
3. `STATE.md`
4. `notes/open_items.md` (full backlog)
5. `PROJECT.md` (this file)
6. Only specific files needed for the current question
