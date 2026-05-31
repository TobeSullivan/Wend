# RULES — Maze Battle TD

**Read `claude-rules.md` first. This file is the project-specific addendum.**

---

## What this project is

A 2D top-down tower defense game inspired by the StarCraft 2 custom map **Random TD**. Built in **Godot**. Target platforms (long term): PC, Mac, consoles, mobile. Phasing TBD.

The original SC2 map died with custom maps. The official spiritual successor (**AMazing TD** by the original Go4 Games team, Steam) shipped to a near-empty playerbase — peak concurrent of 3 as of last check, 70 lifetime reviews. Niche is unoccupied in practice. Failure modes of AMazing TD are addressable (art, multiplayer cold-start, missing QoL features, regression from predecessor).

This project's goal: make the game the SC2 audience actually wanted.

---

## Storage layer

- **GitHub repo: https://github.com/TobeSullivan/tower_defense**
- The repo root contains: `STATE.md`, `PROJECT.md`, `DESIGN.md`, `DESIGN_MODES.md`, plus content directories (`src/`, `notes/`, etc.)
- **The Claude.ai Project folder contains ONLY this file and `claude-rules.md`.** Nothing else. All actual content lives in the GitHub repo.

### Fetching files from GitHub

Use raw URLs, not blob URLs. Raw URLs bypass the HTML wrapper and return file content directly:

```
https://raw.githubusercontent.com/TobeSullivan/tower_defense/main/STATE.md
https://raw.githubusercontent.com/TobeSullivan/tower_defense/main/DESIGN.md
https://raw.githubusercontent.com/TobeSullivan/tower_defense/main/DESIGN_MODES.md
```

Blob URLs (`github.com/.../blob/main/...`) return cached GitHub HTML and are unreliable for reading current file content. Always use raw.

---

## Tooling split

- **This Claude (web/desktop chat)** is for **design, planning, research, and writing**. Used for design conversations, market research, mechanic discussions, generating design artifacts.
- **Claude Code** is for **implementation**. Once code work begins (Godot scripts, shader work, asset pipeline, netcode), the user switches to Claude Code with direct repo access. This Claude does not write game code beyond illustrative snippets.

This split means: design discussions should produce design artifacts (full files at wrap), not code. Claude Code reads those artifacts when it starts implementation work.

---

## Project-specific conventions

### Design decisions are sticky once locked

The design conversation surfaces many decisions per session. Anything explicitly locked goes into `DESIGN.md` or `DESIGN_MODES.md`. Anything still open lives in `STATE.md` under "Open questions." Once locked, decisions don't get re-litigated unless the user opens that thread explicitly — Claude doesn't re-pitch alternatives to settled questions.

### Strong opinions, lightly held — extra hard on design

Game design especially: Claude should push back on suspect choices, present steelmanned alternatives, and flag risks. But once the user makes a call, Claude moves on. Don't re-raise the same concern in three different turns.

### No code from this Claude unless explicitly asked

Even illustrative snippets should be small and clearly marked as illustrative. The user switches to Claude Code for actual implementation. If the conversation drifts toward "let's write the code for this," remind the user that's the Claude Code handoff point.

### Research is fair game

Market research, competitor analysis, IP/legal framing, mechanic references — all in scope for this Claude. Use web search liberally for current data (player counts, reviews, similar games, legal precedent).

---

## What ends up in the repo (long-term shape)

```
<repo-root>/
├── claude-rules.md          # (mirror of the master, or reference)
├── RULES.md                 # (this file, mirrored to repo)
├── STATE.md                 # Current focus, last session, next step
├── PROJECT.md               # Map of what exists
├── DESIGN.md                # Core gameplay design decisions
├── DESIGN_MODES.md          # Modes, maps, progression, seasons, UI, resource architecture
├── src/                     # Godot project source
├── art/                     # Placeholder asset pack + final art
├── levels/                  # Campaign mission definitions
└── notes/                   # Working notes, market research, references
```

The Claude.ai Project folder only ever holds `claude-rules.md` and `RULES.md`.

---

## Phasing posture

The user wants to move from design into prototyping quickly. Don't get lost in design indefinitely. The bar for "good enough to start prototyping" is a coherent core loop, locked mechanics for one mode (single-player), and a clear next-thing-to-build. We don't need to design every feature before code starts.

Multiplayer, guilds, console ports, mobile crossplay, friends integration, hosting infrastructure — all deferred until the core game is playable.
