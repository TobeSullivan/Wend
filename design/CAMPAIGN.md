# Campaign — curriculum, tutorial beats, build guidance

**Read `claude-rules.md` → `RULES.md` → `STATE.md` first.** Mode rules and the mode comparison table live in `design/DESIGN_MODES.md`; this file owns the campaign's teaching design in detail. Map-resource schema and threshold formula are in `DESIGN_MODES.md` (§ map resource / thresholds).

Reworked 2026-06-06. Replaces the 2026-05-31 ten-mission curriculum.

---

## The problem this fixes

The old curriculum was **inverted**. Mission 1 ("First Contact") exposed everything at once — 3 checkpoints, 4 zones, 8 obstacles, 100 supply, 10 rounds — and mission 2 *stripped back* to pure mazing. A brand-new player's literal first match was the single most complex map in the early game, and the game got *simpler* before it got harder. The doc stated the intent plainly ("the forgiving big-sandbox intro that exposes everything at once"); that intent was wrong.

The fix: complexity **ramps from zero**, one new concept per mission, training wheels on early and off by the end.

---

## Curriculum (five missions)

Purpose is tutorial only. A player should be through all five in well under an hour and into Trials/Ranked. Not a selling point; do not get lost building campaign content.

| # | Teaches (the one new thing) | CP | Zones | Ghost outline | Notes |
|---|---|---|---|---|---|
| 1 | The core twist · place a tower · a basic maze | 0 | 0 | **full** | ~10 supply, very short. Entry→exit, no waypoints. The whole point is "what is this game." |
| 2 | Checkpoints force the route | 2 | 0 | lighter (first segment only) | Maze the segments *between* the fixed waypoints. |
| 3 | A longer forced route | 3 | 0 | hint-only | Same idea, more waypoints. Reinforcement, minimal hand-holding. |
| 4 | Bonus zones | 1 | a few | off | Back to 1 CP so **zones are the only new variable**. Introduce the four zone types. |
| 5 | Integration — "almost a real match" | 2–3 | several | off | Everything together, **contained and non-random** (hand-authored, not a generated map). Bridge into Trials Scale 5. Crit/multishot surface here via upgrades. |

**Tuning integers (supply/rounds/mobs/zone mix) are deliberately omitted** — they're uncalibrated and blocked on (a) the 25×14 board retune and (b) real playtest scores. The *shape* of the ramp is what's locked here; CC/we fill the integers when data exists. Board is **25×14** (per STATE.md), not the 40×22 the old doc cited.

**Crit and multishot get no dedicated mission.** They're taught through the upgrade stats (tooltips) and earned by playing the M5 integration map. There are no crit/multishot bonus zones — only DAMAGE / ATTACK_SPEED / RANGE / SLOW exist.

**Gating:** all five unlocked from the start (curve is guidance, not a gate). First-launch still force-loads M1 (per `DESIGN_MODES.md` first-launch flow). The forced first map is now an actual gentle intro rather than the hardest early map.

**Thresholds:** B/S/G medals still apply (they feed season-pass milestones) via the existing derived-threshold formula in `DESIGN_MODES.md`. They're soft and uncalibrated like everything else. M1's should be gentle by design — it's a teaching map, not a wall.

---

## Tutorial-beat system

The old schema carried a single `mission_description` string per mission. Real teaching needs **ordered beats**: short text that fires at specific moments, optionally anchored to a UI element or board region, optionally driving a ghost outline.

**Design source of truth is this file.** The *runtime storage shape* (a beats field on the map resource vs a per-mission sidecar resource) is CC's call to make at implementation — only the five campaign maps carry beat data; Trials/Ranked maps never touch it. This is a schema reopen; flag it as such when CC picks it up.

A beat, conceptually:

```
beat:
  trigger:  <game event that fires this beat>
  text:     <the line shown to the player>
  anchor:   <optional: UI element or board region to point at>
  ghost:    <optional: tiles to highlight / clear — see build guidance below>
  blocking: <bool — does play pause until acknowledged? default false>
```

Triggers (the events the campaign needs):

- `on_mission_load` — before anything, used for the framing line
- `on_build_phase_start` — first time the player can place towers
- `on_first_tower_placed`
- `on_round_start` — player pressed Start Round
- `on_first_kill` — first mob destroyed (and therefore first respawn)
- `on_round_end`
- `on_win`

Beats are **non-blocking callouts by default** (a toast/speech-bubble that doesn't freeze the game), so the game never feels like a slideshow. The single exception is M1's opening framing beat, which is `blocking: true` — the player acknowledges the core twist before the first build. Everything after is advisory and dismissible.

---

## Build guidance (ghost outline)

A programmatic overlay that shows *where to build* to form a proper maze, so the spatial lesson lands without a wall of text.

- **Rendering:** dashed tile highlights + semi-transparent (≈40% alpha) tower footprints on target tiles, drawn from existing primitives (a tilemap highlight layer + a ghost sprite). **No new art assets** — nothing CC has to source or that doesn't exist in the pack.
- **Data:** the mission's beats supply target tiles. A `ghost` payload lists tiles to prompt; when the player places a tower there, that tile's prompt clears.
- **Two states per tile:** *prompted* (dashed + ghost footprint, "build here") and *satisfied* (cleared once filled).
- **Training-wheels schedule:** full on M1 (outline the entire starter maze), partial on M2 (only the first between-checkpoint segment, then let them finish), hint-only on M3 (a couple of suggestion tiles, no full path), **off from M4 on** — the player mazes unaided before zones and integration enter.

The outline teaches "long path = more damage" by construction. By the time zones appear (M4) the player already builds mazes without it.

---

## Tutorial copy

Real lines, not placeholders. Tone: plain, confident, a little blunt — matches the game's "this isn't normal TD" identity. Tighten in voice pass; the content is what matters here.

### Mission 1 — the twist + first tower + basic maze

- **`on_mission_load` (blocking):**
  > "Forget everything you know about tower defense. These enemies don't die — they shatter and instantly re-form, then keep marching. You'll never stop them, and you're not supposed to. Your only job is to deal as much damage as you can before the rounds run out. The longer you force them to walk through your fire, the higher you score."

- **`on_build_phase_start` (anchor: board, ghost: starter maze tiles):**
  > "Place towers on the glowing tiles. Don't just line them up — bend the path. Every extra step the enemy takes is another second your towers get to shoot."

- **`on_first_tower_placed` (anchor: the placed tower):**
  > "That's a tower. It fires at anything in range. Tap it any time to upgrade it."

- **`on_round_start`:**
  > "Here they come. Watch what happens when one falls."

- **`on_first_kill` (anchor: the respawn point):**
  > "See? It's already back and walking again. You're not killing them — you're farming damage off them. That number climbing in the corner is the only thing that matters."

- **`on_round_end` (anchor: score):**
  > "That's your score. Bronze, Silver, Gold are targets to chase, but the real game is the leaderboard. For now — keep going."

- **`on_win`:**
  > "That's the whole game. Everything from here just adds wrinkles. Next: the enemy won't walk in a straight line for you anymore."

### Mission 2 — checkpoints (2)

- **`on_mission_load`:**
  > "The enemy now has to touch two waypoints before it leaves. You can't change where those are — but you decide the path *between* them. Make every leg as long as you can."
- **`on_build_phase_start` (ghost: first segment only):**
  > "We'll outline the first stretch. Finish the rest yourself — squeeze in as much walking as the space allows."

### Mission 3 — checkpoints (3)

- **`on_mission_load`:**
  > "Three waypoints this time. Same job, more room to be greedy with the path. You've got this — only a couple of hints from here."
- **`on_build_phase_start` (ghost: hint tiles only):** no full outline; a few suggestion tiles, then hands off.

### Mission 4 — bonus zones (1 checkpoint)

- **`on_mission_load`:**
  > "New thing: bonus zones — the colored circles on the board. A tower sitting inside one gets stronger. Red boosts damage, yellow attack speed, blue range, and the cold ones slow enemies to a crawl right where your fire is thickest. Smaller circle, bigger bonus."
- **`on_build_phase_start` (anchor: a zone):**
  > "Only one waypoint here, so the only new decision is the zones. Build your maze so your best towers stand inside them — and so the enemy lingers in the slow zones."

### Mission 5 — integration

- **`on_mission_load`:**
  > "No more training. This map has everything — checkpoints, zones, a full run — but it's hand-built, not random, so you can learn it. This is what a real match feels like."
- **`on_build_phase_start` (anchor: upgrade panel):**
  > "One last tip: pouring upgrades into a few towers unlocks crit and multishot — going *tall* often beats going wide. Experiment. Then go play Trials and Ranked for real."

---

## Handoff notes for CC

- Five missions, ramp from zero. Old ten `.tres` files in `levels/campaign/` are **deprecated** — cut or repurpose against the repo as you see fit; design now describes five.
- Tutorial-beat data is a **schema reopen**: pick a runtime shape (sidecar resource vs map-resource field), only the five campaign maps carry it. Design intent is in this file.
- Ghost outline is programmatic overlay, **no new art**.
- Tuning integers and B/S/G thresholds are uncalibrated → wait on the 25×14 retune + playtest. Don't invent final numbers; stub gentle values for M1 so the tutorial is winnable.
