# Meta-structure & campaign shape — v0 draft

Captured 2026-05-30. A **first-pass shape** to react to and refine in the next
chat — NOT locked design, NOT a build order. The job next session: turn this into
a real plan, then build it. Where DESIGN.md already locks something, it's marked
**[LOCKED]**; everything else is an open decision.

The prototype proved the in-match mechanics. This doc is about everything *around*
a match: how the player gets in, out, and through a campaign.

---

## 1. Screen flow (the shape)

```
Boot
 └─> Main Menu ──────────────────────────────────────────────┐
       ├─ Play        ─> Save Slot Select ─> Level Select     │
       ├─ Settings    ─> Settings screen                      │
       └─ Quit                                                 │
                                                               │
 Level Select ─(pick level)─> MATCH                            │
       ▲                                                       │
       │   In-match overlays:                                  │
       │     • Pause menu: Resume / Settings / Restart / Quit ─┘ (Quit -> Level Select)
       │     • Win modal (hit Gold): Keep Playing / Return ───── (Return -> Level Select)
       │     • Match-end modal: medal + scores / Next / Replay / Level Select
       └───────────────────────────────────────────────────────
```

Key point: **Level Select is the "home"** that Pause→Quit, the Win modal, and
Match-end all return to. Building it unblocks those buttons (which currently just
reload the level).

---

## 2. Screens — what each needs

### Main Menu
- Play, Settings, Quit. Maybe Credits later. Background art TBD.

### Save Slots
- Proposed: **3 slots**. Each slot = one campaign profile.
- Per slot UI: empty → "New Game"; used → shows progress (e.g. "5/12 levels, 3 gold"), "Continue" / "Delete".
- **Open:** how many slots? Is profile name/avatar a thing? (Recommend: 3 slots, no naming, keep it simple.)

### Settings (shared by main-menu Settings and in-match pause Settings)
- Candidate list: master / music / SFX volume; default game speed (ties to FF); fullscreen + resolution; damage-numbers toggle.
- Persisted to `user://settings.cfg` (global, not per-slot).
- **Open:** final list of settings.

### Level Select
- Shows the campaign's levels: locked/unlocked state, **best medal** (●bronze/silver/gold), **best damage score** per level.
- Layout: simple grid/list first; a "campaign map" visual is a later polish.
- Pick a level → load its recipe → start match.

---

## 3. Data models

### Level recipe (one data file per level — the "framework")
Moves today's hardcoded config out of `main.gd`/`round_manager.gd` into data:
- grid size, entry/exit cells, checkpoint cells (1–3) **[LOCKED: Points = 1–3]**
- supply cap **[LOCKED: per-map var]**
- enemy supply (mob count) **[LOCKED: per-map var]**
- bonus zones (type, magnitude, position)
- obstacles (prop, footprint, position)
- round cap + mob-HP curve params
- Bronze / Silver / Gold thresholds **[LOCKED: 3 thresholds per level]**
- (campaign metadata: level id, name, what it teaches)

### Save profile (per slot)
- per-level: best medal + best damage score + completed flag
- overall unlock progress
- **Open:** is anything else stored per slot (playtime, settings override)?

---

## 4. Campaign formula — "what the campaign actually is"

What DESIGN.md already locks **[LOCKED]**:
- SP campaign = scripted, hand-designed missions; everything fixed, no randomization.
- Win = hitting a damage threshold; **Bronze = beat the level**, Silver/Gold for engaged players.
- No lives in SP. Leaderboard score = total damage dealt.
- Each level is built deliberately to teach a specific lesson.

What's **OPEN** (decide next chat):
- **Count & grouping:** how many levels at launch? Flat list, or worlds/chapters
  (e.g. 4 worlds × 5 levels)?
- **Unlock gating:** linear (beat level N's Bronze to unlock N+1)? Or star-gated
  (need X total medals to open the next world)? — Recommend linear-Bronze to start.
- **Teaching progression:** the spine of the campaign. Rough sketch to debate —
  L1 basic mazing (no zones/obstacles), L2 introduce a bonus zone, L3 introduce
  obstacles + routing tradeoffs, L4 tighter supply forces specialization, L5
  multi-checkpoint long route, etc. Each new level adds exactly one idea.
- **Difficulty knobs per level:** supply, enemy supply, zone count/magnitude,
  checkpoint count, HP curve, round cap — these are the dials that make a level
  easy/hard and teach its lesson.
- **Progression rewards:** do medals unlock anything (cosmetics?), or are they
  purely score/bragging? (DESIGN implies leaderboard bragging; no unlock economy
  mentioned.)

---

## 5. Suggested build order (for next chat to confirm)
1. Level recipe system — load the current test map from a data file (proves the framework with zero new content).
2. Level Select (basic list) reading recipes + showing best medal/score from the save profile.
3. Save slots + profile persistence (`user://`).
4. Main menu + settings (+ wire pause-menu Settings to the same screen).
5. Author levels 1–N against the recipe format once the teaching spine is agreed.

> Everything here is a starting shape. Next chat: pressure-test it, lock the
> campaign formula, then plan #1 (level recipe system) in detail and build.
