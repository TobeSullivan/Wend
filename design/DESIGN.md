# Design

Locked design decisions for the game. Anything in this document is settled and not re-litigated without explicit reopening. Open questions live in `STATE.md`, not here.

Modes, maps, progression, seasons, and the mission/map resource architecture live in `DESIGN_MODES.md`.

---

## Pillars

The design rests on four pillars. Every other decision serves these.

> **2026-06-22 pivot:** the original "damage milking" pillar (mobs respawn; no fail state) was reversed after external playtesting. Mobs now die permanently and a lives-based fail state returns. See `notes/design_revisions_2026-06-22.md` for the full rationale.

**Simple to learn, hard to master.** One tower type, one standard mob type (plus a periodic boss). The entire vocabulary of the game can be taught in five minutes. Mastery comes from reading geometry, identifying optimal placement, and committing to where and how you build the merge ladder — not from memorizing tower charts or wave compositions.

**Survive the escalation.** Mobs die and stay dead, like a conventional TD. Difficulty ramps until it outpaces the player: a normal maze caps out around stage 30, a great maze pushes further. The player is climbing as far as their maze can carry them, not milking an infinite resource.

**Learning through defeat.** Multiplayer reveals opponents' mazes during the run phase, by player choice. Watching the leader's maze teaches you how they're winning. Losing is informative, not just punishing.

**Commitment matters.** Towers merge along a fixed tier ladder; merging empties the source tile and leaves a hole in the maze. Refund is 30% of total invested. Build decisions are sticky and spatial. Bad decisions hurt; good decisions compound.

---

## Inspiration and positioning

The game is a spiritual successor to **Random TD**, a StarCraft 2 custom map by the Go4 Games team. The team's standalone successor **AMazing TD** (Steam, 2021) shipped to a near-empty playerbase. Failure modes were: poor art direction (Greek god theme widely criticized), dead multiplayer at launch (cold-start spiral), regression from the SC2 predecessor's feature set, missing QoL features veterans expected.

This project's positioning: make the game the SC2 audience actually wanted. Distinct art, strong single-player offering, bot multiplayer to solve the cold-start problem, faithful mechanics with modern polish.

---

## Core gameplay loop

A match consists of rounds. Each round has two phases:

**Build phase (timed).** Player places towers, upgrades existing towers, sells towers. Other players' mazes are hidden during this phase.

**Run phase (untimed).** A train of mobs spawns at the map's entry point and walks to the exit, hitting required checkpoints in order. Towers fire automatically. Mobs die permanently when killed; a mob that reaches the exit **leaks** and costs lives. Every tenth round a boss rides among the wave (leaking it costs a heavy chunk of lives). The run phase ends when the train is gone (all killed or leaked). During this phase the arena is visible — the player can watch their own maze or any other player's.

After the run phase ends, lives transfer between players based on **leak differences** (PVP only — fewer leaks than the field gains lives, more loses them; score breaks ties), then the next build phase begins. In Trials, leaks cost the player lives directly and the run ends when they hit zero.

---

## Towers

There is exactly one tower type in the game.

Towers fire automatically at the front of the mob train within range. Default targeting is first-in-line (mob nearest to exit, within range). Targeting behavior is not player-configurable at launch.

### Merge tier ladder

> Supersedes the former six-stat free-form upgrade system (2026-06-22 pivot).

A tower's power comes from its **tier**, raised only by merging: two towers of tier N combine into one tier N+1. Pure merge — there is no per-stat upgrade purchase, and nothing other than merging raises tier. Tiers run **T1 → T10**; because each tier doubles the base-tower cost (2ⁿ), high tiers are aspirational and reached only with a strong economy.

**Merging empties the source tile**, leaving a hole in the maze. This is the core tension: climbing the ladder thins your wall, and re-plugging holes competes with the build timer.

All combat stats derive from tier (damage, range, fire rate). **Multishot is the dominant lever**, unlocking at **T3 / T6 / T10 → ×2 / ×3 / ×4** (cap 4). Because DPS = damage × shots × fire rate, multishot tiers compound hardest. Exact per-tier scaling is deliberately deferred (placeholder curves in code mirror `notes/wend_merge_reference.html`); balance comes later.

Crit is parked under the tier model — the plumbing is kept for projectiles/cosmetics but no tier grants crit at launch.

### Merge input

- **Controller / Steam Deck (primary target):** move the cursor to a tower, press action to **arm** it (it lifts), then press a direction to merge that way. Auto-disarms. An invalid direction (empty / wrong tier / maxed) gives a reject nudge.
- **Mouse:** drag a tower onto an adjacent same-tier tower.

### No specialization or evolution

Towers do not specialize, branch, or unlock milestone effects. The only progression axis is the merge tier ladder. If players request specialization after launch, it can be revisited. For now: no.

### Visual identity (per-tier morph)

A tower's appearance encodes its tier at a glance:

- **Barrel count = shot count** — the functional read lives in structure, not body colour, so the body stays a pure skin slot (cosmetics decision).
- **Body colour walks a 10-stop ramp** across tiers (warm → cool) when no skin is equipped.
- **Tier badge** shows the exact tier number, upright.
- **T10 gets a gold accent ring.**

Tower–zone synergy stays visible, and spectating an opponent's maze still reveals their strongest towers (highest barrel counts / badges) from across the map.

### Selling

Towers are atomic. The player cannot partially refund. Selling a tower refunds **30% of total gold invested**, including the base placement cost of every tower folded into it via merges.

---

## Mobs

There is one standard mob type, plus a periodic boss.

Each round, a fixed-size train of mobs spawns at the map's entry point. The train walks in a line toward the exit, passing through each required checkpoint in order.

When a mob is killed, it dies permanently. A mob that reaches the exit **leaks**, costing lives. The round ends when the train is gone — every mob either killed or leaked.

**Boss rounds.** Every tenth round, a boss rides among the wave (not a solo encounter). It carries much more HP and leaking it costs a heavy chunk of lives.

**Mob HP scales between rounds.** Working curve: flat for rounds 1-5, then approximately ×1.12/round. This is a global constant, not a per-map variable, and it is the difficulty ramp that eventually outpaces the player (~stage 30 for a normal maze). Mob count per round (Enemy Supply) is a per-map variable and does not change round-to-round. Mob speed is constant.

---

## Bonus zones

Bonus zones are colored circles painted on the map. A tower whose footprint **touches** a zone receives that zone's bonus. Partial overlap is sufficient.

### Types

Two functional categories:

- **Tower buffs** — apply to towers placed in the zone: damage, attack speed, range, crit chance, crit damage, multishot.
- **Mob debuffs** — apply to mobs walking through the zone: slow.

Working color assignments: damage = red, attack speed = blue, range = green, slow = cyan. Crit/multishot colors TBD.

### Magnitude and size

Zone magnitude (bonus strength) is inversely proportional to zone size. High magnitude = small zone. Low magnitude = large zone. Magnitudes are stepped in 10% increments (10%, 20%, ..., 100%).

Formula: `r_tiles = max(0.75, 4.0 - (mag - 10) / 30)`. Linear inverse. Subject to playtest tuning.

### Stacking

A tower benefiting from two zones of the same type gets both bonuses added together additively. Different-type zones apply independently.

Procgen guarantees no more than two zones overlap at any point on the map.

### Labels

Each zone displays its type and magnitude in the center (e.g. `DAMAGE +20%`). White text, black outline.

---

## Economy

Each player's gold income each round:

**Round bonus** — flat gold per round: 25 + round number.

**Kills** — 1 gold per mob killed during the run phase. Kill income scales with how much of each round's wave your maze can clear.

**Interest** — 1 gold per 10 gold currently saved, awarded at round end. Capped at 50 gold per round (interest flatlines once the player has 500 saved).

Starting gold: 250. Tower placement cost: 10 gold.

---

## Pathing

Mobs always take the shortest path from current position to the next required checkpoint (entry → cp1 → cp2 → cp3 → exit). Placed towers are walls. Path uses A* with string-pull to produce direct lines where unobstructed and route around towers only where forced.

**Towers cannot be placed if they would fully block the path** to any required checkpoint. The placement system rejects invalid positions.

Path is recalculated only when the maze changes (tower placed, tower sold). Towers cannot be placed, sold, or upgraded during the run phase.

---

## Wave structure

### Build phase timing

- Round 1: 30 seconds
- Rounds 2–29: 25 seconds (working number, tunable)
- Round 30+: compressed to 5–10 seconds (soft pacing tool, not a hard cap)

### Run phase timing

Untimed. Ends when the mob train fully exits the map. Longer mazes get more time-on-tower per mob — maze length is a temporal weapon.

### Boss rounds

Every tenth round a boss rides among the wave (see Mobs). This is the one scheduled escalation beat; it is deterministic, not random.

### No mid-match shake-ups

No random events, no special waves, no armor-resistance mobs. Every round is mechanically the same except for mob HP, the scheduled boss every 10 rounds, and the player's evolved maze.

---

## Anti-goals

What this game is explicitly NOT:

- **Not a mob-variety TD.** One standard mob type plus a single periodic boss. No bestiary.
- **Not a tower-variety TD.** One tower type. Forever. Depth comes from the merge ladder, not a roster.
- **Not an RNG TD.** No surprise waves, no random events mid-match. The boss cadence is fixed (every 10 rounds). The map is randomized at start; the match is not.
- **Not a free-flexible upgrade TD.** No per-stat upgrade shopping; power comes only from the merge tier ladder.
- **Not a specialization/evolution TD.** No milestone effects, no tower evolution. May revisit post-launch if players request it.
- **Not the SC2 map verbatim.** Inspired by Random TD. We do not reuse tower names, level names, art style, UI layouts, or specific tuning values from Random TD or AMazing TD.
- **Not Greek-themed.**

---

## Out of scope at launch (Phase 2 or later)

- Guilds and guild rankings
- Cross-platform play and cross-platform friends
- Console ports
- Mobile
- Additional mob-debuff zone types beyond launch set
- Type-specific zone shapes (launch is all-circles)
- Hosting infrastructure decisions
- Player-configurable targeting behavior
