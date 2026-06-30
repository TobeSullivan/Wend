# State — Wend
Last updated: 2026-06-29 (Jira cutover)

## Current focus
(1) Steam **Playtest live** — tracking real player data now (supersedes the prior "in review"
state); (2) **this session (design):** co-op Trials redesigned into a **damage relay**, the
in-match **rail reworked**, and the **board-viewing picker** locked. All handed to CC. (3) Balance
and leaderboard dials being fitted against live Playtest data.

## Last session (design, this Claude)
Reworked multiplayer/board-view after the 2026-06-22 mobs-die pivot broke the old co-op model.
- **Co-op Trials = damage relay (shape locked, dials TBD).** Separate boards, one shared spawn
  stream, lockstep rounds; mobs flow board 1→N **carrying HP**; life lost **only at the final
  board's exit**. **Shared lives + supply + symmetric gold** (a kill anywhere pays every player
  the same — kills not damage); boards + spend independent. Seed = base+position. Rounds primary
  / summed-damage tiebreak. **Ranked is NOT a relay.** Resim flag: carried-HP needs a
  deterministic cross-board mob handoff.
- **Rail rework.** Cut `Menu` (Esc = pause) + `Build [B]` (B key); drop the second-box header
  (`STANDING/STARS/SCORE`). Freed slot → `Boards` (MP only); Ranked `Boards` absorbs the old
  `Leaderboard` pop-out.
- **Board-viewing locked.** Single-board camera focus + a **names picker** (no grid). `Boards`
  toggles a pop-out names list (number badge = hotkey, you = row 1); **`1`–`8` jump** via
  `focus_board(i)`. Reuses existing green-frame/"Spectating {name}"/back chrome. Thumbnail grid
  **parked**.

## Next step
- **CC:** implement `notes/coop_relay_and_boards_handoff.md` — build order: (1) rail rework,
  (2) picker + 1–8 hotkeys + restyle spectate chrome, (3) the relay (start with the
  carried-HP cross-board handoff in sim+resim, then shared lives/supply/gold, then tune dials).
- Carry-over: playtest each scale once → fit `SCALE_HP_MULT` / `TRIALS_STAR_ROUNDS` from
  `playtest_log.jsonl`; playtest the tier aura; rewrite stale tutorial copy; `test_case_library.md`
  edits owed (§3 + aura case).

## Recently touched (this session)
- design/DESIGN_MODES.md (co-op relay + arena), design/INMATCH_HUD.md (rail + board-viewing),
  notes/decisions.md (relay + rail + board-viewing locks), notes/coop_relay_and_boards_handoff.md
  (NEW), notes/mockups/wend_boards_popout_names_final.png + wend_spectate_overlay.png +
  wend_boards_popout_B_thumbnails.png (NEW), STATE.md

## Task & bug tracking
Discrete tasks and bugs now live on the **Jira board (project KAN)** —
https://wendthegame.atlassian.net/jira/software/projects/KAN/boards/2 — not in a repo ledger.
`notes/open_items.md` is retired; must-not-reverse locks are in `notes/decisions.md`, deferred
seeds in `notes/parked.md`.

## Open questions / blocked on
- **Co-op dials:** shared-lives integer, shared-supply/density budget, bounty, per-scale
  area/point caps. Shape locked, numbers move — fitting against live Playtest data now.
- **Ranked second box:** drop entirely vs host picker inline — Tobe to eyeball (not blocking).
- Per-tier stat curves + lives integers being tuned against live Playtest data.
