# State

Last updated: 2026-05-30

---

## Current focus

**Home screen, first-launch flow, and pause menu locked.** This session closed the remaining UI navigation design: first-launch forced mission 1, simple two-button home screen (PVE / PVP) for returning players, pause menu spec with single-player vs multiplayer variants, and Esc priority stack. Specialization/evolution removed from design entirely. All three artifacts updated: `DESIGN.md`, `DESIGN_MODES.md`, `RULES.md`.

**Next build focus: mission/map resource framework in Godot.** Implement `MapResource`, `ZoneDefinition`, `GameConstants` autoload, `map_generator.gd`, and `map_loader.gd`. Refactor `main.gd` to consume a `MapResource` instead of hardcoded values. Author `mission_01.tres` as the first campaign mission to validate the authoring workflow.

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

**For Claude Code:**

1. Create `src/resources/game_constants.gd` — autoload singleton, move all magic numbers from existing scripts into it
2. Create `src/resources/map_resource.gd` — MapResource schema (extends Resource)
3. Create `src/resources/zone_definition.gd` — ZoneDefinition sub-resource
4. Create `src/scripts/map_loader.gd` — reads MapResource, configures scene
5. Refactor `main.gd` — remove all hardcoded map config, consume MapResource via map_loader
6. Create `src/campaign/mission_01.tres` — first campaign mission, hand-authored, validates the workflow
7. Create `src/scripts/map_generator.gd` stub — takes seed + scale tier, returns MapResource (full procgen algorithm TBD, stub sufficient to unblock campaign work)

Do these in order. Each step unblocks the next.

**For this Claude (design):**

- Leaderboard backend design (captured in `notes/leaderboards.md` — needs updating with mode decisions)
- PVP LP curve (exact points per placement TBD)
- Season pass point values and milestone thresholds
- Damage threshold calibration (needs real playtest data)
- Soft caps for damage / range / attack_speed upgrade stats

---

## Recently touched files

- `DESIGN.md` — specialization removed, anti-goals updated
- `DESIGN_MODES.md` — home screen, first-launch flow, pause menu spec added
- `RULES.md` — GitHub URL added, raw URL fetch guidance added
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
