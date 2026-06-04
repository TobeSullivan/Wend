# Project Map

One-line index of what exists in this project. Read at start of every session for orientation.

---

## Repo root files

- `claude-rules.md` — Universal Claude rules (mirror of master copy)
- `RULES.md` — Project-specific addendum to claude-rules
- `STATE.md` — Current focus, last session, next step, open questions
- `PROJECT.md` — This file. Map of what exists.
- `.gitignore` — Ignores `art/` (third-party asset pack source), dev artifacts, OS junk

## Directories

- `design/` — All locked design docs:
  - `DESIGN.md` — core game design decisions
  - `DESIGN_MODES.md` — modes, maps, progression, seasons, UI, map-resource architecture
  - `VISUAL_SYSTEM.md` — canonical visual language (palette, type, icons), menu + PVP UI specs
  - `INMATCH_FIXES.md` — scoped Claude Code in-match tasks (obstacle schema, movement chevron)
- `src/` — Godot 4 project (open `src/project.godot` in Godot). Contains `scenes/`, `scripts/`, `resources/`, `campaign/`, `assets/`, and its own `.gitignore` for the `.godot/` cache.
- `src/scenes/prototype.tscn` — Main scene. Single Node2D root with `main.gd` attached. `main.gd` is a thin host: it loads a `MapResource` and hands it to `map_loader`.
- `src/scripts/` — All gameplay scripts (`main`, `mob`, `tower`, `projectile`, `spawner`, `build_controller`, `upgrade_panel`, `round_manager`, `hud`, `pathfinder`, `bonus_zone`, `obstacle`, plus `map_loader` and `map_generator`).
- `src/resources/` — `game_constants.gd` (GameConstants autoload — all global tuning), `map_resource.gd` + `zone_definition.gd` (the map schema shared by all modes).
- `src/campaign/` — Hand-authored campaign mission `.tres` files (`mission_01.tres` is the first). Up to 10 missions.
- `src/assets/` — Curated subset of the asset pack actually used by the project (tower sprites, zombie animations, map tiles, level markers). Committed.
- `art/` — Full third-party asset pack as dropped in. Source-of-truth for what we pull into `src/assets/`. **Gitignored** for license safety.
- `levels/` — Legacy/unused; campaign mission definitions now live in `src/campaign/` as `.tres` files.
- `notes/` — Working notes, market research, references. `video_frames/` subdir holds debug frame extracts and is gitignored.

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
4. `PROJECT.md` (this file)
5. Only specific files needed for the current question
