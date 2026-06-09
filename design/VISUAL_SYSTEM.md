# Visual System — Maze Battle TD

Last updated: 2026-06-04
Repo path: `design/VISUAL_SYSTEM.md`

This is the canonical look. The in-match HUD already implements it; everything else
(menus, modal panels) migrates onto it. The **blue dark-panel theme** and the
**wooden plank theme** are RETIRED — delete their styles from `ui_style.gd`.

---

## Palette

All values already live in `ui_style.gd` under the "Mockup flat theme" block — this
just promotes them to be the only vocabulary.

- **Surfaces:** pill/panel `#323d2c` (border `#1a2012`) · chip `#39402c` (border `#23170d`) · dock/card `#2a3322` (border `#161c0f`)
- **Accents:** gold / economy / score `#b38e2c` (border `#5e4710`) · green / primary "go" `#5fbe38` (border `#2c5a18`) · terracotta / destructive / sell `#b04a2a` (border `#5e2310`)
- **Text:** white `#ffffff` on dark surfaces · sage labels `#b9c7a4`
- **Backdrop:** toned grass (`modulate 0.72, 0.80, 0.62`) — full-bleed in match, static behind menus

Green is reserved for the in-match "go" action (Start Round) and primary buttons.
Do not spend it on neutral menu buttons.

## Shape & elevation

- Corner radius **16** (pills/buttons) · **18** (cards/docks)
- Border 2px, bottom border **+2** for a soft bevel
- Shadow `rgba(0,0,0,0.42)`, offset y `+5`, blur `~7`
- Flat fills only — no gradients

## Typography — REQUIRED FIX

Font: **Fredoka, weight ~600 (SemiBold)**, white with a 2–3px dark outline
(`#1a2012`); optional 2px bottom drop-shadow on large titles.

**Known bug:** `src/assets/fonts/fredoka.ttf` is the variable font, but its DEFAULT
weight is **Light (300)** (the name table literally reads "Fredoka Light"). So text
renders thin and "set it bold" silently does nothing. Fix (reliable first):

1. Ship a static **Fredoka-SemiBold.ttf** and use it directly. *(recommended — can't silently fail)*
2. `FontVariation.variation_embolden = 0.35` on the existing file.
3. `variation_opentype = { TextServer.name_to_tag("weight"): 600 }` **and** make the
   project default font point at the `.tres`, not the bare `.ttf`.

The **outline** is a Label property (`font_outline_color` + `outline_size`), NOT a font
setting — already done per-button in `ui_style.gd`. Promote it to a shared `Theme` so
every Label inherits weight + outline instead of each control re-declaring it. That is
what stops the "looks thin in Godot" problem recurring screen by screen.

## Iconography — use ONLY assets that exist in the pack

Icons load from `res://assets/ui/icons/...`. **Menu buttons are text-forward; an icon
is added only where a confirmed PNG exists.** Never spec an icon we haven't verified —
that's what strands Claude Code.

Confirmed mappings used in this pass (`art/ui/icons/icons_128_px/` unless noted):

| Use | Asset |
|---|---|
| Settings / gear | `settings_2.png` |
| PVE (co-op) | `group.png` |
| PVP (ranked) | `podium.png` |
| Campaign | `map_icon.png` (ui_icons) |
| Quit (game) | `cross.png` |
| Back | `arrow_left.png` |
| Tier badge | `trophy.png` |
| Gold / coin | `coin_silver_gold.png` (ui_icons) |
| Restart | `replay.png` |
| Quit to menu | `home.png` |
| Reached / done | `tick.png` |
| Speed | `fast_forward.png` |
| Lives (heart) | `heart_face_on.png` / `heart_tilted.png` (ui_icons) |
| Spectate (eye) | *no clean eye icon — use text "Spectating" or confirm an asset* |

**Medals: there are NO medal sprites.** Tiers are shown as **stars** (real assets:
`gold_star_type_01_full.png` etc. in `ui_icons`, plus the `level_map_parts` 1/2/3-star
compositions). Mapping: 3★ = old gold, 2★ = silver, 1★ = bronze, empty = unattempted.
This is a representation swap only — same per-mission medal data underneath.

## Menu backdrop

Menus sit on an **inert static surface**: the toned grass + a darkening vignette, as a
dumb image. NOT a live match — no board logic, no mobs, no input. **No fabricated
decoration** (no drawn trees/towers/ghost-mazes — they read as fake). Floating UI on top,
same tokens as in-match. If "empty" ever needs filling, it's a real rendered battlefield
snapshot judged in-engine, not hand-drawn filler.

---

## Screens

All five menu screens were designed against the system (reference mockups produced
2026-06-04). Layouts are landscape (phone-first; PC scales up and centers).

### Home
- Hierarchy by SIZE, not color: **PVE** and **PVP** are two equal large hero buttons,
  center. **Campaign** is a smaller, lower-contrast tertiary button below (it's the tutorial).
- Slim ambient **season bar** top-center (label + progress + tier badge), not dominant.
- Settings gear top-right; **Quit** bottom-left. Real icons per the table.

### Campaign select
- 5×2 grid of 10 mission cards, **all unlocked** (no gating — curve is guidance).
- Each card: mission number + **lesson label** (Intro, Mazing, Checkpoints, Zones, Slow,
  Crit, Multishot, Supply, Economy, Capstone) + **star tier** in the corner (0–3).
- Lesson labels are real content (fills the cards, reinforces "tutorial").

### PVE select
- Daily / Weekly / Monthly tab bar (active tab lit).
- Five Scale 1–5 map cards, **text-forward stats** (Rounds / Supply / Zones / Mobs /
  Checkpoints) + best score with a gold star ("No score yet" if unplayed).

### Pause (overlay over a dimmed board)
- Single-player variant: **Your score** + the three **star objectives** (1★/2★/3★ with the
  score-to-beat, `tick.png` on reached, unreached dimmed), then **Resume** (green primary) /
  Settings / Restart / Quit to menu. Button contents centered.
- Multiplayer variant: no objectives block (no medals in PVP); **Restart → Quit Match**.

### Settings (overlay; auto-saves on close → top-right close button)
- Rows: Master / Music / SFX **sliders**; Game speed **segmented** 1×/2×/3×; Fullscreen
  **toggle**; Resolution **dropdown**; Damage numbers **toggle**. All map to standard
  themed Godot controls (HSlider / CheckButton / OptionButton).

---

## Naming TODO (NOT locked)

"PVE" / "PVP" are dev terms, not player-facing. Candidates: **Co-op / Versus** (lean), or
themed (Onslaught / Clash, etc.). Once chosen, update labels across home, the select
screens, and the PVP leaderboard.

---

## PVP UI

- **Drop the SCORE pill in PVP** — placement/lives is the judgment, a score number doesn't
  make sense. Keep **lives + kills** top-right.
- **Arena = a toggle-able LEADERBOARD** (replaces the wooden left rail + "Map" button):
  - Ranked 1–8 by lives: position + **player name** + lives. Your row **green-highlighted**.
  - Eliminated rows show **OUT** and sink to the bottom.
  - Solo queue = stranger handles → names **truncate with ellipsis**, fixed row height.
- **Tap a name → spectate that board.** Board contents: **live during run**; **last
  snapshot during build** (if seen before); **"?" if never seen**. Thumbnails are static —
  only the ONE spectated board renders live. **Never render 8 live thumbnails** (that is the
  prior 8-board-FX crash).
- **Spectate safeguards** (prevent "build on the wrong board"):
  - Top-center banner **"Spectating <name>"** (green).
  - **Green inset frame** around the screen while spectating (absent on your own board).
  - Always-present **"Back to your board"** button.
  - **HARD RULE:** build phase **force-returns** the camera to your own board, regardless
    of who you were watching.
