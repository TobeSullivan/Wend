# State — Wend
Last updated: 2026-06-05

> **Read order:** `claude-rules.md` → `RULES.md` → this file → `notes/open_items.md` (full backlog) → only the specific file the task needs.
> **History:** older session logs were moved to `STATE_ARCHIVE.md` — reference only, don't load unless you're digging into a past decision.

---

## ⚠️ Recent reversals — do NOT act on stale instructions
The archive (and older memory) describe a **mobile-first** direction. That is **DEAD as of 2026-06-05.**

- **Platform: PC/Mac-first. Mobile NEVER** (console if the game succeeds; mobile only revisited on viral success). A mobile build would be a *fork* — different board, different leaderboard, different game — not a port, because you can't resize the board and keep crossplay.
- **Board is going UP to ~23×14** (~+50%, ~66px tiles), **reversing the 20×11 mobile shrink.** The old "design for the smallest screen / rescale campaign to 20×11" plan is superseded: the board **grows**, and campaign `.tres` rescales to the **new** size, not 20×11. Final tile count pending the user's feel-check of `notes/mockups/inmatch_board_fullsize_1920.html`.
- **In-match UI:** current spec is the **2026-06-05 mockups** — recessed dark-grass surround + bright bounded board arena, flex layout, right inspector dock, redesigned victory panel. This **supersedes the earlier full-bleed-grass mockup**. See `notes/mockups/`.
- **Pricing: $10–15 (PC band)** — the old $5 was the mobile number. Saves = **Steam Cloud**.

---

## Name
**The game is "Wend"** (locked 2026-06-05; confirmed clear on Steam). Placeholder was "Maze Battle TD." Genre signal goes in a subtitle/tagline ("Wend — a maze battle TD"), not the name. **Player-facing mode names: "Trials" (PVE), "Ranked" (PVP).**

## Current focus
**Dedicated-server deploy (active CC track).** M1 headless netcode is committed (`d884368`); next concrete step is deploying the headless Godot server to the **Hetzner VPS** (CPX11, Ashburn) — user provisioning the box. One match per server for now (Option A); concurrency is the later Option-B step. See `notes/server_decision.md`, `notes/remote_beta_plan.md`, `notes/multiplayer_architecture.md`.

The 2026-06-05 design direction (reversals above) governs the next UI/board work.

## Last session (2026-06-05 — design session 2, no code)
Knocked out a stack of open design items to clear the deck for CC. Resolved: **game name → "Wend"** (Steam-clear; unblocks the store page), **mode names → Trials / Ranked**, **PVE window cadence** (keep daily/weekly/monthly), **vertical slice** (reframed to the beta/demo, not a formal slice), **leaderboard group scoring** (per-team, separate boards by size), the full **PVP LP ladder** (new `notes/pvp_ladder.md` — MMR-anchored net-positive, Bronze→Masters, season behavior; numbers are playtest dials), **soft caps** (governed-by-economy, no change; revisit only if gold/rounds/supply/board-size shift — CC checks the live log then), and **accessibility/zone icons** (label+color+uniform-shape baseline; verified icons for speed/slow/damage, range stays label-only — no target glyph exists in the pack). Earlier same-day session 1 locks (PC-first, $10–15, Nakama, mazing pillar, etc.) already captured in `open_items.md`.

## Next step
- **CC:** finish the Hetzner deploy. Then rebuild in-match UI from `notes/mockups/`, re-rescale board + campaign `.tres` to the confirmed ~23×14 (**not** 20×11). New CC chores from this session: (1) **rename PVE→"Trials" / PVP→"Ranked"** in code strings (home_screen, pve/trials select, leaderboard surfaces) + a doc label-pass in `DESIGN_MODES.md`; (2) copy `energy.png` + `waiting.png` from `art.zip` into `src/assets/ui/icons/` and import (for the damage/slow zone icons); (3) **point `DESIGN_MODES.md`'s "LP curve TBD" line at `notes/pvp_ladder.md`**.
- **Design (mostly their own sessions):** juice/game-feel pass · full GTM + Steam page (now unblocked by the name) · anti-cheat system · season-pass numbers · Trials group-lobby flow · onboarding for non-SC2 players · IP/legal framing.

## Recently touched files
- `notes/pvp_ladder.md` — **NEW**, full Ranked LP/MMR/tier/season spec
- `notes/open_items.md` — full backlog ledger, **start here for what's open** (8 items resolved this session)
- `notes/leaderboards.md` — group scoring locked per-team, window cadence resolved, Trials/Ranked names
- `RULES.md`, `PROJECT.md` — name (Wend) applied
- `notes/season_pass.md`, `notes/pvp_lobby.md`, `notes/server_decision.md`, `notes/gtm.md`
- `notes/mockups/inmatch_ui_layout_v3.html`, `inmatch_board_fullsize_1920.html`, `inmatch_juice_taste.html`

## Open questions / blocked on
Full per-item status lives in **`notes/open_items.md`**. Active right now: board final tile count (feel-check pending) · Trials group-lobby flow · anti-cheat (own session) · GTM/Steam page (own session) · season-pass numbers. Blocked on data: B/S/G threshold calibration, PVP seed-convergence.
