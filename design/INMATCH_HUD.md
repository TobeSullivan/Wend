# In-Match HUD — Layout

Repo path: `design/INMATCH_HUD.md`
Status: **SIGNED OFF 2026-06-07 · IMPLEMENTED 2026-06-08 (CC)** — right panel, board maximization, and tower info are built (`src/scripts/rail.gd`, `tower_drawer.gd`, `ui_layout.gd`; retired `hud.gd`/`action_strip.gd`). One decision refined at build time: **tower info docks IN the rail's lower gap by default** (the flagged in-rail alternative — measured to fit at 1080p with ~175px clearance), falling back to the over-board overlay only on windows too short to hold it. Board overlays (pop-out leaderboard, spectate banner, round-end overlay) remain noted but not yet specced.

Visual tokens (palette, radii, bevel, shadow, Fredoka SemiBold + outline) are inherited from `design/VISUAL_SYSTEM.md` and not repeated here. This doc is **layout + content**, not styling.

---

## Layout model (locked)

- **One reserved panel** holds everything persistent. It sits **outside the board** on the **right edge** (rail). Full-bleed was tried and failed — UI over the board made towers hard to select/place and occluded the field even with click-through. Persistent UI gets its own space.
- **The board maximizes into the remainder.** Tile size is the readability floor; cell count fills the leftover area (see Board section — TBD, pending the maximization pass). The rail being width-bound is the board's tighter axis, so the rail's px cost comes out of width.
- **Contextual UI overlaps the board** and is dismissable on a deliberate click (select tower → inspector; click off / Esc → gone). Contextual = tower overlay, pop-out leaderboard, spectate banner, round-end overlay. None of these live in the rail.

---

## Right rail — three boxes, top to bottom

Fixed width. Every element justified (label left / value right). Fixed-width containers; text truncates with “…”, never runs on. All buttons share one footprint.

### 1. Status box — identical in both modes
| Row | Value |
|---|---|
| Round | `n / total` |
| Phase | `Build · m:ss` (timer folded into the phase row) / `Run` |
| Supply | `n / total` |
| Gold | `n` (gold-colored) |

### 2. Second box — content swaps by mode, frame fixed
The box never resizes; both modes fill the same fixed frame so the Buttons box anchors at the same Y. **2026-06-29: drop the box header label** (`"STANDING"/"STARS"/"SCORE"`, `rail.gd:165`) on all screens — it wastes vertical space and "STARS" was inaccurate (it's the Trials board, which merely *starts* with 1–3 star milestones). The rows are self-evident without it. (Ranked open option: the box is low-value mid-run since Standing resolves at round end — drop it entirely or host the picker inline; not blocking, default keeps the box header-less.)

**Trials → SCORE (a climbing display).** Hero row `Current n`, then up to three **rungs** = whatever targets remain *above* current score, ascending:
- Below 1★: `Current` · 1★ · 2★ · 3★
- Past 1★: `Current` · 2★ · 3★ · `‹ghost/leaderboard name›`
- Past 2★, nothing loaded above: `Current` · 3★ · *(blank)* · *(blank)*

Passed stars fall off the top; the next leaderboard ghost climbs in from the bottom. When nothing is ahead (or offline, no backend feed), rungs go blank **but hold their height**. This is the ghost-ladder concept (`notes/ghost_ladder.md`) bound to the rail frame — offline correctly falls to blanks, the named ghost lights up only when the leaderboard backend feeds it.

**Ranked → STANDING.** Hero row `Lives n` (lives is the survival currency, so it's the hero number, paralleling Current in Trials), then:
- `Kills n`
- `Rank n / 8`
- *(one blank slot to match Score-box height)*

**All three Standing values are frozen during the run and resolve together at round end.** Lives transfer resolves at round end, so rank is undefined mid-run — showing a live rank would assert information that doesn't exist yet. No mid-run flicker.

### 3. Buttons box — same footprint every button
Top to bottom; primary is the green slot.

| Slot | Co-op Trials | Ranked | Solo Trials / Campaign |
|---|---|---|---|
| Primary (green) | Start Round | Ready `N/8` | Start Round |
| Secondary | Speed `3×` | Boards (picker) | Speed `3×` |
| — | Boards (picker) | — | — |

- **Cut 2026-06-29:** `Menu` is removed — Esc already opens the pause menu (the standard, and why it was "Menu" not "Pause"); the button was pure redundancy. `Build [B]` is removed — the `B` key opens build and nobody used the button. Discoverability for both lives under pause → Options → **Controls** (`Esc = menu`, `B = build`, `left = place`, `hold Shift = chain-place`, `right = sell`, `1–8 = jump to board`); tutorial players already know them.
- The freed slot becomes **Boards** — the board-viewing picker (multiplayer only; see *Board-viewing* below). Solo Trials / Campaign show no Boards button (nobody to watch).
- **Ranked:** Boards **replaces and absorbs** the old never-built `Leaderboard` pop-out — same 8-player surface, one button.
- **Speed** changes only in run phase (locked). During build it is present-but-disabled (greyed); in run, Start Round is gone and Speed is active.

---

## Kills — home depends on mode
Kills standalone does nothing in Trials (it drives gold but gold is its own indicator), so in **Trials it lives on the tower overlay** as per-tower contribution, not the rail. In **Ranked, kills are the lives-transfer engine** (pairwise zero-sum, Model B), so kills are persistent in the Standing box.

---

## Round-end overlay — one shared system
The round-end resolution beat already has a visual language in Trials (gold / score deltas popping on resolution). Ranked reuses the **same** overlay system to show the **lives swing (`+3 / −2`)** from the pairwise transfer. One overlay to build, not two: Trials shows gold/score gains, Ranked shows lives ±. It's an event over the board, not persistent rail state.

---

## Board maximization (locked)

Cell **size** is fixed (the current good on-screen size); cell **count** grows to fill the area left of the rail. Procedure:

1. Reserve the rail on the right (~280px at 1080p — holds the three boxes; adjustable).
2. The board area is the remainder, minus a small uniform margin.
3. At the **1080p reference**, fit the fixed tile size into that area: `cols = floor(area_w / tile)`, `rows = floor(area_h / tile)`. This yields **25 × 16** (the old 25×14 width was already full; the two extra rows fill what used to be the top/bottom letterbox gutter).
4. **The count is locked universal.** Every player runs 25×16 regardless of monitor — leaderboards and maze geometry must be identical for all. Other resolutions **scale the whole board and center it**; they do not get more or fewer cells. Fixed tile size is the design-time input that *picks* the count, not a per-machine guarantee.
5. If the grid doesn't divide the area evenly, **center the board** (even margins). At 1080p that remainder is tiny (~20px sides, ~28px top/bottom).

Why decide it now: changing the count is normally expensive (resets leaderboards, forces a full campaign remap). Right now leaderboards are empty and the campaign + editor don't exist yet, so this was the cheapest moment to set it. **25×16 is now the number the campaign editor authors against.**

## Tower overlay (locked)

Identical to the current in-game tower panel, with three changes: it's a **contextual overlay** over the board (not a reserved dock), the **hide button is removed**, and **Sell** reads just "Sell" (no refund amount — 30% refund still applies, just not shown).

- **Content:** header (TOWER / name / `Lv n · selected`), six stat rows as one shared 4-column grid — **Stat · Now · Cost · [+]** — aligned down the panel; then **Total damage · n kills**; then **Sell**. No column headers. This is where **Trials kills** live (per-tower contribution).
- **Behavior:** appears on tower-select, dismisses on click-off / Esc. **Fixed anchor** (top-right, hugging the board's right edge) — it does *not* follow the selected tower around the board (a jumping panel would occlude different cells and feel restless). Content updates to the selected tower; position holds.
- **Range ring** draws on the board on select (existing behavior; lives with the overlay, not inside it).
- **Build-time decision (2026-06-08): in-rail by default + overlay fallback.** Measured the rail's lower gap at the 1080p reference (~495px free beneath the Buttons box; tower panel ~305px → ~175px clearance), so tower info now **docks in the rail's lower gap** (zero board occlusion) and only falls back to the over-board overlay when the window is too short to hold it (below ~900px tall, since the desktop rail is fixed-px). Both placements implemented in `tower_drawer.gd`; the rail exposes `tower_slot_rect()` (empty ⇒ fall back).

---

## Board-viewing — picker + spectate (LOCKED 2026-06-29)

How you watch other players' boards in multiplayer. Model = **single-board camera focus + a
picker** (not a grid). Most of it is already coded in `game_view.gd` (`focus_board(i)`,
`_focus`, green frame / "Spectating {name}" banner / back button); this locks the entry + nav.
Full CC handoff + mocks: `notes/coop_relay_and_boards_handoff.md`.

- **Picker = a names list** (mock `notes/mockups/wend_boards_popout_names_final.png`). Pop-out
  drawer toggled by the `Boards` button, centered over the board, dims the play area, Esc/tap-
  off closes. **Never persistent** over the board (persistent-over-board failed — occludes
  building even with click-through). One row per player = **number badge (= hotkey) + avatar +
  name + chevron**, no status (pure navigation). **You are always row 1** (green); others 2–N
  (Trials 2–4, Ranked 2–8). Row tap → `focus_board(i)`.
- **Hotkeys (PC/Mac):** `1`–`8` jump straight to a board via `focus_board` (no picker needed);
  `1` = your board. Deck/console/mobile handled at port time.
- **Jumped-to board** (mock `notes/mockups/wend_spectate_overlay.png`): existing green frame +
  "Spectating {name}" banner + back pill — **restyle to tokens** (`START_BG`/`START_BORDER`,
  back pill `PILL_BG`/`PILL_BORDER`, Fredoka SemiBold + outline). When `_spectate_index !=
  local_index`, suppress tower inspector + build + sell and don't route taps to
  `build_controller` (read-only).
- **Build phase:** boards hidden; picker/hotkeys run-phase only; build auto-returns home.
- **Parked:** a 4×2 live-thumbnail grid (mock `wend_boards_popout_B_thumbnails.png`) — reads
  fine but lots of code for minimal gain; revisit later.

## Deferred / next in this area
- **Campaign map editor** — now unblocked by the 25×16 lock; hand-authoring grid (board / obstacle / tower-ghost / checkpoint cells + resizable zone circle). See `notes/polish_punchlist.md` item 9.
- Speed-during-build: present-but-disabled (current) vs empty-until-run — only open detail on the rail.
