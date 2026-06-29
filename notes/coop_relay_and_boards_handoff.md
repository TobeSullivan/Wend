# CC handoff — Co-op Trials relay + rail rework + Boards picker

**Session 2026-06-29.** Three connected changes, all design-locked this session. The
**shape is locked; the numbers are not** (flagged TBD/playtest where they are). Canonical
specs updated in `design/DESIGN_MODES.md` (co-op mode) and `design/INMATCH_HUD.md` (rail +
board-viewing UI); locks promoted to `notes/decisions.md`. This doc is the single read that
ties them together for implementation.

Mocks (ship with this wrap, in `notes/mockups/`):
- `wend_boards_popout_names_final.png` — **the locked Boards picker** (build against this).
- `wend_spectate_overlay.png` — the spectate chrome (green frame + "Spectating {name}" + back)
  composited on a real in-match capture. This is what a jumped-to board looks like.
- `wend_boards_popout_B_thumbnails.png` — **parked** thumbnail-grid alternative. NOT building
  now (lots of code, minimal gain), kept for a possible later revisit.

---

## 1. Co-op Trials is now a DAMAGE RELAY (mode redesign)

The old co-op model (everyone runs a parallel board, team score = sum of damage, fixed rounds)
**no longer fits** the 2026-06-22 pivot (mobs die permanently + lives fail state). A parallel
model degenerates into "summed solos, hope nobody leaks." Replaced with a relay.

**The model (LOCKED):**

- **Separate boards, one shared spawn stream, in lockstep.** Each player has their own maze.
  Everyone builds together, runs together, same wave schedule (same round at all times).
- **Mobs flow board 1 → 2 → … → N.** A mob that exits player 1's board *enters* player 2's
  board, then player 3's, etc. **A life is lost ONLY when a mob exits the FINAL board** in the
  chain. Intermediate "leaks" are just handoffs, not life loss.
- **Carried HP.** A mob keeps its remaining HP across boards — board 1 softens, the middle
  chips, the last board finishes. (NOT a fresh full-HP copy per board — that would just be N
  solos with the last one mattering.)
- **Shared lives.** One team pool. Trials base × N is the starting point (per-capita capacity
  held constant) — TBD, playtest.
- **Shared supply.** One pool spread across N boards → every board is deliberately
  *under-towered* vs a solo board. **This is the mechanism that makes the relay real:** no
  single board can clear a late wave alone, so mobs survive downstream by design. Per-board
  density must land *below* solo-clear. The supply/area/point budget needs a redesign around
  this target — TBD, playtest.
- **Shared symmetric gold — kills, not damage.** A kill anywhere pays **every player the same
  gold** (solo = 1g/kill → co-op = the same kill credits 1g to each of the N players). Killer
  identity and damage dealt are irrelevant. This deletes the upstream-snowball problem
  (otherwise board 1 sees all the killable HP and out-earns the back, decaying the relay into
  "board 1 is the game"). Gold accrues whether or not you personally build.
- **Independent boards, independent building.** Each player spends their own gold on their own
  board, their own way. (Pools are shared for *lives/supply/gold-income*; the board itself and
  the spend are the player's.)

**Strategy this unlocks (design intent, for context — not a task):** because gold accrues
passively, *not building is viable*. A back-seat player can bank + watch + coach while the
front carries early rounds, then drop a planned, optimized maze later. Seats are asymmetric:
board 1 = the softener (every mob, full HP, most action); middle = relay; last = the
goalkeeper (low traffic if the team's good, but the only seat where a leak costs a life). This
is the first *functional* reason to watch a teammate's board (see §3).

**Seed scheme (LOCKED) — fairness across the leaderboard:**

Each player at position *p* in a group plays map seed `base + (p-1)`. The group's set of maps
is fixed and ordered, so every Duo of a given window/scale is the same two maps in the same
order; every Trio the same three; etc. Each *position* is a distinct map (distinct zones /
maze geometry) within that scale's authored range (Snarl is `x–y` points / `x–y` zones, etc.).

```
tangle solo  -> 1 map : seed 123
tangle duo   -> 2 maps: 123, 124
tangle trio  -> 3 maps: 123, 124, 125
tangle quad  -> 4 maps: 123, 124, 125, 126
```

Reproducible, re-simmable, leaderboard-fair. Position 1 always plays 123 regardless of who
sits there.

**Scoring / leaderboard:** unchanged board structure (Daily/Weekly/Monthly × Solo/Duo/Trio/
Quad). The team shares rounds-reached (they die together), so **rounds-reached is the team
primary key, summed damage across boards the tiebreak** — consistent with the round-based
Trials leaderboard already shipped. Group size = the board (no vote).

**RESIM / DETERMINISM FLAG (the real implementation cost):** carried-HP across boards means
the authoritative re-sim must hand each mob's state **across player-board boundaries** inside
the deterministic log — a cross-board mob handoff event, ordered, replayable. The single
shared spawn stream + shared seed already give a deterministic spine; the new piece is the
boundary crossing carrying HP. Worth pinning before this locks in code.

**Still TBD (deferred to playtest / CC tuning, by design):** shared-lives integer, shared-
supply budget + per-board density target, bounty/gold values, board area/point caps per scale.
The *shape* above is locked; these dials move.

**Ranked is NOT a relay.** This is co-op Trials only. Ranked stays 8-player independent boards,
pairwise lives-transfer, last-standing (unchanged). The Boards picker (§3) is shared UI; the
relay economics are not.

---

## 2. In-match rail rework (`rail.gd`)

Frees space and removes redundant chrome. Applies in both modes except where noted.

**Buttons box — cut the redundant buttons:**
- **Cut `Menu`.** Esc already opens the pause menu (the standard, and why it's "Menu" not
  "Pause"). The button is pure redundancy. Discoverability for non-tutorial players lives under
  pause → Options → **Controls** (list: `Esc = menu`, `B = build`, `left-click = place`,
  `hold Shift = chain-place`, `right-click = sell`, `1–8 = jump to board`).
- **Cut `Build [B]`.** The `B` key opens build; nobody uses the button. (Keep it in the
  Controls list above.)
- The freed slot becomes **`Boards`** (the picker, §3) — multiplayer only.

Resulting buttons box:
- **Ranked:** `Ready` + `Boards`. (Boards **replaces and absorbs** the old never-built
  `Leaderboard` pop-out — same 8-player surface, one button.)
- **Co-op Trials:** `Start Round` + `Speed` + `Boards`.
- **Solo Trials / Campaign:** `Start Round` + `Speed`. (No Boards — nobody to watch.)

**Second box (`_build_score_box`) — drop the header:**
- Remove the box header label entirely (`"STANDING"/"STARS"/"SCORE"` at `rail.gd:165`). The
  header is wasted vertical space and "STARS" is inaccurate (it's the Trials board, which just
  *starts* with 1–3 star milestones, not a stars board). Drop the header on **all** screens;
  the content (Round/Current hero + rungs in Trials, Lives/Kills/Rank in Ranked) stays and is
  self-evident from its rows.
- **Ranked specifically does not need this box at all** — Standing resolves at round end and is
  low-value mid-run. Open option (Tobe to eyeball): in Ranked, either drop the box or let the
  freed space host the picker inline. Not blocking; default = keep the box, drop the header,
  ship the picker as a pop-out (§3) for now.

---

## 3. Boards picker + spectate navigation (the half-baked piece, now specced)

The board-viewing model is **single-board camera focus + a picker** — already ~half-coded in
`game_view.gd` (`focus_board(i)`, `_focus`, the green frame / "Spectating {name}" banner /
back button). What was missing is the surface that *chooses* whose board to view, and the
keys. That's this.

**Picker = a names list (LOCKED — build `wend_boards_popout_names_final.png`):**
- A contextual pop-out drawer, toggled by the `Boards` button. Centered over the board, dims
  the play area, `Esc`/tap-off closes. **Never persistent** over the board (persistent-over-
  board was tried and failed — occludes building even with click-through).
- One row per player: a **number badge (the hotkey) + avatar + name + jump chevron**. No
  status text (we don't reliably have leak/mob counts, and it's pure navigation anyway).
- **You are always row 1**, green-bordered; others are 2–N (Trials 2–4, Ranked 2–8).
- Row tap → `focus_board(i)`. The row number doubles as the keyboard shortcut, so the picker
  *teaches* the hotkeys.

**Hotkeys (LOCKED, PC/Mac):**
- **`1`–`8` jump straight to a board** via `focus_board(i)` — no need to open the picker.
  `1` = your board (= `local_index`), `2`–`N` = the others in order. Trials uses `1`–`4`,
  Ranked `1`–`8`. Steam Deck / console / mobile get a different affordance at port time
  (out of scope now).

**Jumped-to board (already coded, just confirm against `wend_spectate_overlay.png`):** camera
focuses that board, green 6px frame, centered "Spectating {name}" banner, "← Back to your
board" pill. Restyle the frame/banner/back to the dark-rail tokens (`ui_style.gd`:
`START_BG`/`START_BORDER` for the green, `PILL_BG`/`PILL_BORDER` for the back pill; Fredoka
SemiBold + outline). When `_spectate_index != local_index`, suppress the tower inspector +
build + sell and don't route board taps to `build_controller` (read-only — you can't edit
someone else's board).

**Build phase:** boards hidden during build (locked). The picker/hotkeys are run-phase only;
build auto-returns the camera to your own board (already in `_on_phase_changed`).

**New code (small, the whole point):** the picker list node (a VBox of numbered rows in the
existing `layer 7` CanvasLayer), the `Boards` button + toggle, and the `1`–`8` key bindings →
`focus_board`. The focus/chrome plumbing already exists.

---

## Build order suggestion
1. Rail rework (§2) — cut Menu/Build, drop the header, add the Boards button. Cheap, unblocks
   the slot.
2. Picker + hotkeys (§3) — the names list + `1`–`8` → `focus_board`. Restyle the existing
   spectate chrome.
3. Co-op relay (§1) — bigger; start with the cross-board carried-HP handoff in the sim +
   resim (the determinism-critical part), then the shared lives/supply/gold plumbing, then
   tune the dials in playtest.
