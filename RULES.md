# RULES — Wend

**Read `claude-rules.md` first. This file is the project-specific addendum.**

---

## What this project is

**Wend** — a 2D top-down tower defense game inspired by the StarCraft 2 custom map
**Random TD**. Built in **Godot**. **PC/Mac-first** (console if it succeeds; mobile is a
*fork*, never a port — revisit only on viral success).

Name locked 2026-06-05 (confirmed clear on Steam as a game title). "Maze Battle TD" was a
placeholder. "Wend" = to make one's winding way — fits the maze. It's a dictionary word, so
it's a weak trademark and gives no genre signal in search; the genre lives in a
**subtitle/tagline** ("Wend — a maze battle TD"), not the name. Player-facing mode names:
**Trials** (PVE), **Ranked** (PVP).

The original SC2 map died with custom maps. The official spiritual successor (**AMazing TD**
by the original Go4 Games team, Steam) shipped to a near-empty playerbase — peak concurrent
of 3 as of last check, ~70 lifetime reviews. Niche is unoccupied in practice. Failure modes
of AMazing TD are addressable (art, multiplayer cold-start, missing QoL features, regression
from predecessor).

This project's goal: make the game the SC2 audience actually wanted.

---

## Storage layer

- **GitHub repo:** https://github.com/TobeSullivan/tower_defense
- The repo root contains: `STATE.md`, `STATE_ARCHIVE.md`, `PROJECT.md`, `RULES.md`,
  `claude-rules.md`, plus `design/`, `notes/`, and `src/`.
- **The Claude.ai Project folder contains ONLY this file and `claude-rules.md`.** Nothing
  else. All actual content lives in the GitHub repo.

### GitHub fetch rule
Always read repo files via `raw.githubusercontent.com/TobeSullivan/tower_defense/main/<file>`
— never `github.com/.../blob/...` URLs (stale cached HTML). If the raw CDN serves a stale
copy right after a push (it caches briefly), a shallow `git clone` is the reliable way to
get current truth.

---

## Tooling split

- **This Claude (web/desktop chat)** is for **design, planning, research, and writing**.
  Used for design conversations, market research, mechanic discussions, generating design
  artifacts.
- **Claude Code** is for **implementation**. Once code work begins (Godot scripts, shader
  work, asset pipeline, netcode), the user switches to Claude Code with direct repo access.
  This Claude does not write game code beyond illustrative snippets.

This split means: design discussions should produce design artifacts (full files at wrap),
not code. Claude Code reads those artifacts when it starts implementation work.

---

## Project-specific conventions

### Design decisions are sticky once locked

The design conversation surfaces many decisions per session. Anything explicitly locked goes
into `DESIGN.md` / the relevant `notes/` file, and resolved items move to the Resolved blocks
in `notes/open_items.md`. Anything still open lives in `open_items.md`. Once locked, decisions
don't get re-litigated unless the user opens that thread explicitly — Claude doesn't re-pitch
alternatives to settled questions.

### Strong opinions, lightly held — extra hard on design

Game design especially: Claude should push back on suspect choices, present steelmanned
alternatives, and flag risks. But once the user makes a call, Claude moves on. Don't re-raise
the same concern in three different turns.

### No code from this Claude unless explicitly asked

Even illustrative snippets should be small and clearly marked as illustrative. The user
switches to Claude Code for actual implementation. If the conversation drifts toward "let's
write the code for this," remind the user that's the Claude Code handoff point.

### Balance/tuning questions belong to CC + the live log

The playtest log (`user://playtest_log.jsonl`) lives on the user's machine, not in the repo.
Only Claude Code (running locally) can read it. Don't design balance numbers in this chat
against imagined data — flag the item, defer the numbers to a CC pass against the real log.

### Research is fair game

Market research, competitor analysis, IP/legal framing, mechanic references — all in scope
for this Claude. Use web search liberally for current data (player counts, reviews, similar
games, legal precedent, name/trademark collision checks).

---

## What ends up in the repo (current shape)

```
<repo-root>/
├── claude-rules.md          # universal rules (mirror of master)
├── RULES.md                 # this file
├── STATE.md                 # current focus, last session, next step
├── STATE_ARCHIVE.md         # older session logs (reference only)
├── PROJECT.md               # map of what exists
├── design/                  # DESIGN.md, DESIGN_MODES.md, VISUAL_SYSTEM.md, INMATCH_FIXES.md
├── notes/                   # backlog ledger + design notes + market research + mockups
└── src/                     # Godot project source
```

The Claude.ai Project folder only ever holds `claude-rules.md` and `RULES.md`.

---

## Phasing posture

The game is near scope-complete; the work now is knocking out remaining open items and
getting the beta/demo shippable, not adding scope. The active build track is the dedicated
server + remote multiplayer (CC). Design sessions clear the open ledger so CC can run.

Cosmetic DLC, perpetual seasons, console ports, localization — deferred until the core game
is playable and shipped.
