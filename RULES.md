# RULES — Wend (working dir: `C:\dev\Maze Battle TD`)

**Read `claude-rules.md` first. This file is the project-specific addendum.**

---

## What this project is

A 2D top-down tower defense game inspired by the StarCraft 2 custom map **Random TD**. Built in **Godot**. Target platforms: PC/Mac-first (console if it succeeds; mobile never, except as a fork on viral success). Name is **Wend** (locked); genre lives in a subtitle.

The original SC2 map died with custom maps. The official spiritual successor (**AMazing TD** by the original Go4 Games team, Steam) shipped to a near-empty playerbase. Niche is unoccupied in practice. Failure modes of AMazing TD are addressable (art, multiplayer cold-start, missing QoL features, regression from predecessor).

This project's goal: make the game the SC2 audience actually wanted.

---

## Storage layer

- **GitHub repo:** https://github.com/TobeSullivan/tower_defense
- **Local working dir:** `C:\dev\Maze Battle TD` (old placeholder name; the game is "Wend").
- Repo root: `STATE.md`, `PROJECT.md`, `RULES.md`, `claude-rules.md`, plus `design/`, `notes/`, `src/`, `levels/`, `art/`.
- **The Claude.ai Project folder contains ONLY this file and `claude-rules.md`.** All actual content lives in the GitHub repo.
- **GitHub fetching:** always use `raw.githubusercontent.com` URLs — blob URLs return stale cached HTML. API directory listings can rate-limit; fetch known files via raw URLs as the reliable fallback.

---

## Tooling split

- **This Claude (web/desktop chat)** is for **design, planning, research, and writing**. It produces design artifacts (full files at wrap), not game code.
- **Claude Code** is for **implementation** (Godot scripts, shaders, asset pipeline, netcode). It reads the design artifacts when it starts work.

Design discussions produce design artifacts. If a conversation drifts toward "let's write the code," that's the Claude Code handoff point.

---

## Project-specific conventions

### Design decisions are sticky once locked
Anything explicitly locked goes into the relevant `design/` or `notes/` file. Open items live in `notes/open_items.md`. Once locked, decisions don't get re-litigated unless the user opens that thread explicitly — don't re-pitch alternatives to settled questions.

### Strong opinions, lightly held — extra hard on design
Push back on suspect choices, present steelmanned alternatives, flag risks. Once the user makes a call, move on. Don't re-raise the same concern across turns.

### No code from this Claude unless explicitly asked
Even illustrative snippets stay small and clearly marked. The user switches to Claude Code for implementation.

### Research is fair game
Market research, competitor analysis, IP/legal framing, mechanic references — all in scope. Use web search liberally for current data.

---

## Wrap deploy — ALWAYS produce the push command

The user deploys wrap artifacts by downloading them, then moving them into the repo and pushing. **At every wrap, after producing the artifacts, emit a single-line Windows PowerShell command** that does the whole move-commit-push. The user should never have to ask for it.

Rules for the command:
- **One physical line. No newlines.** Chain statements with `;`. (Pasting breaks if it contains line breaks.)
- **Quote every path** — the working dir is `C:\dev\Maze Battle TD` and contains a space.
- **Route each file to its correct repo subdirectory** (`design\`, `notes\`, or root). Do NOT blanket-move everything to root — that misfiles `design/` and `notes/` docs. Move files individually with explicit destinations.
- **Use `-Force`** on `Move-Item` so edited files overwrite the existing repo copies.
- Source is the Downloads folder (`$env:USERPROFILE\Downloads`).
- End with `git add -A`; a `git commit -m "..."` whose message is a one-line summary of the session; and `git push`.

Template shape (fill in the session's actual files + destinations):

```powershell
$r='C:\dev\Maze Battle TD'; $dl="$env:USERPROFILE\Downloads"; Move-Item "$dl\FILE.md" "$r\SUBDIR" -Force; ...; cd $r; git add -A; git commit -m "ONE-LINE SUMMARY"; git push
```

---

## What ends up in the repo (long-term shape)

```
tower_defense/
├── claude-rules.md
├── RULES.md
├── STATE.md
├── PROJECT.md
├── design/        # DESIGN.md, DESIGN_MODES.md, VISUAL_SYSTEM.md, CAMPAIGN.md, INMATCH_FIXES.md
├── notes/         # market research, MP architecture, resim contract, leaderboard, matchmaking, open_items, mockups/
├── src/           # Godot project source
├── art/           # asset pack + final art
└── levels/        # campaign + generated map resources
```

The Claude.ai Project folder only ever holds `claude-rules.md` and `RULES.md`.

---

## Phasing posture

Move from design into prototyping quickly; don't get lost in design indefinitely. "Good enough to start" = a coherent core loop, locked mechanics for one mode, and a clear next-thing-to-build. Multiplayer, guilds, console ports, friends integration, hosting infrastructure are sequenced per `STATE.md` / `notes/open_items.md`, not all designed before code starts.
