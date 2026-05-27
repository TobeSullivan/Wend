# RULES — <Game Project Name TBD>

**Read `claude-rules.md` first. This file is the project-specific addendum.**

---

## What this project is

A 2D top-down tower defense game inspired by the StarCraft 2 custom map **Random TD**. Built in **Godot**. Target platforms (long term): PC, Mac, consoles, mobile. Phasing TBD.

The original SC2 map died with custom maps. The official spiritual successor (**AMazing TD** by the original Go4 Games team, Steam) shipped to a near-empty playerbase — peak concurrent of 3 as of last check, 70 lifetime reviews. Niche is unoccupied in practice. Failure modes of AMazing TD are addressable (art, multiplayer cold-start, missing QoL features, regression from predecessor).

This project's goal: make the game the SC2 audience actually wanted.

---

## Storage layer

- **GitHub repo** (URL TBD — to be created)
- The repo root contains: `STATE.md`, `PROJECT.md`, `DESIGN.md` (or `design/` if it splits), plus whatever content directories emerge as the project develops (`src/`, `art/`, `levels/`, etc.)
- **The Claude.ai Project folder contains ONLY this file and `claude-rules.md`.** Nothing else. All actual content lives in the GitHub repo.

---

## Tooling split

- **This Claude (web/desktop chat)** is for **design, planning, research, and writing**. Used for design conversations, market research, mechanic discussions, generating design artifacts.
- **Claude Code** is for **implementation**. Once code work begins (Godot scripts, shader work, asset pipeline, netcode), the user switches to Claude Code with direct repo access. This Claude does not write game code beyond illustrative snippets.

This split means: design discussions should produce design artifacts (full files at wrap), not code. Claude Code reads those artifacts when it starts implementation work.

---

## Project-specific conventions

### Design decisions are sticky once locked

The design conversation surfaces many decisions per session. Anything explicitly locked goes into `DESIGN.md`. Anything still open lives in `STATE.md` under "Open questions." Once locked, decisions don't get re-litigated unless the user opens that thread explicitly — Claude doesn't re-pitch alternatives to settled questions.

### Strong opinions, lightly held — extra hard on design

Game design especially: Claude should push back on suspect choices, present steelmanned alternatives, and flag risks. But once the user makes a call, Claude moves on. Don't re-raise the same concern in three different turns.

### No code from this Claude unless explicitly asked

Even illustrative snippets should be small and clearly marked as illustrative. The user switches to Claude Code for actual implementation. If the conversation drifts toward "let's write the code for this," remind the user that's the Claude Code handoff point.

### Research is fair game

Market research, competitor analysis, IP/legal framing, mechanic references — all in scope for this Claude. Use web search liberally for current data (player counts, reviews, similar games, legal precedent). The user came in wanting to understand the SC2 map and the market; that kind of work continues to be useful.

---

## What ends up in the repo (long-term shape)

```
<repo-root>/
├── claude-rules.md          # (mirror of the master, or reference)
├── RULES.md                 # (this file, mirrored to repo)
├── STATE.md                 # Current focus, last session, next step
├── PROJECT.md               # Map of what exists
├── DESIGN.md  OR  design/   # Design decisions (split when it grows)
├── src/                     # Godot project source (when implementation starts)
├── art/                     # Placeholder asset pack + final art
├── levels/                  # Campaign mission definitions
└── notes/                   # Working notes, market research, references
```

The Claude.ai Project folder only ever holds `claude-rules.md` and `RULES.md`.

---

## Phasing posture

The user wants to move from design into prototyping quickly. Don't get lost in design indefinitely. The bar for "good enough to start prototyping" is a coherent core loop, locked mechanics for one mode (single-player), and a clear next-thing-to-build. We don't need to design every feature before code starts.

Multiplayer, guilds, console ports, mobile crossplay, friends integration, hosting infrastructure — all deferred until the core game is playable.
