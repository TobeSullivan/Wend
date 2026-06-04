# Design

Locked design decisions for the game. Anything in this document is settled and not re-litigated without explicit reopening. Open questions live in `STATE.md`, not here.

Modes, maps, progression, seasons, and the mission/map resource architecture live in `DESIGN_MODES.md`.

---

## Pillars

The design rests on four pillars. Every other decision serves these.

**Simple to learn, hard to master.** One tower type, one mob type. The entire vocabulary of the game can be taught in five minutes. Mastery comes from reading geometry, identifying optimal placement, and committing to where and how you invest — not from memorizing tower charts or wave compositions.

**Damage milking, not survival.** Mobs don't die permanently — they explode and respawn in place. The player isn't trying to stop the wave; they're trying to maximize damage dealt against an effectively infinite resource within a bounded window. This inverts standard TD pressure.

**Learning through defeat.** Multiplayer reveals opponents' mazes during the run phase, by player choice. Watching the leader's maze teaches you how they're winning. Losing is informative, not just punishing.

**Commitment matters.** Towers are atomic — no degrading, no selling partial upgrades. Refund is 30% of total invested. Build decisions are sticky. Bad decisions hurt; good decisions compound.

---

## Inspiration and positioning

The game is a spiritual successor to **Random TD**, a StarCraft 2 custom map by the Go4 Games team. The team's standalone successor **AMazing TD** (Steam, 2021) shipped to a near-empty playerbase. Failure modes were: poor art direction (Greek god theme widely criticized), dead multiplayer at launch (cold-start spiral), regression from the SC2 predecessor's feature set, missing QoL features veterans expected.

This project's positioning: make the game the SC2 audience actually wanted. Distinct art, strong single-player offering, bot multiplayer to solve the cold-start problem, faithful mechanics with modern polish.

---

## Core gameplay loop

A match consists of rounds. Each round has two phases:

**Build phase (timed).** Player places towers, upgrades existing towers, sells towers. Other players' mazes are hidden during this phase.

**Run phase (untimed).** A train of mobs spawns at the map's entry point and walks to the exit, hitting required checkpoints in order. Towers fire automatically. Mobs explode and respawn in place when killed. The run phase ends when all mobs in the train have exited the map. During this phase the arena is visible — the player can watch their own maze or any other player's.

After the run phase ends, lives transfer between players based on kill differences (PVP only), then the next build phase begins.

---

## Towers

There is exactly one tower type in the game.

Towers fire automatically at the front of the mob train within range. Default targeting is first-in-line (mob nearest to exit, within range). Targeting behavior is not player-configurable at launch.

### Upgrade stats (six)

A tower can be upgraded across six independent stats. The player buys tiers of each stat freely; no branching, no exclusion. Upgrade costs scale per tier.

- **Damage** — flat damage per hit. Effectively uncapped; cost makes high tiers impractical.
- **Range** — how far the tower can reach. Soft-capped at a level where additional range serves no practical use given map dimensions.
- **Attack Speed** — hits per second. Soft-capped; at the cap, further investment rounds to zero and the UI reads "MAX."
- **Crit Chance** — percentage of hits that crit. Hard-capped at 75%.
- **Crit Damage** — multiplier on crit hits. Hard-capped (working ~500%, TBD).
- **Multishot** — additional targets per attack. Hard-capped at +3 additional (4 total).

### No specialization or evolution

Towers do not specialize, evolve, or unlock milestone effects. The upgrade system is free-form across all six stats with no branching outcomes. If players request specialization after launch, it can be revisited. For now: no.

### Color modulation (visual identity)

A tower's visual color encodes its upgrade state at a glance. Each stat has a color assignment (working: damage = red, attack speed = blue, crit chance = yellow, crit damage = orange, range = green, multishot = purple — TBD). As the tower accumulates tiers in a stat, its color shifts toward that stat's hue. Multiple investments blend like physical paint.

Consequences of this system, all intentional:

- Pale towers are visibly under-invested
- Vivid mid-tones mean a tower is heavily invested in one or two stats
- Maxed-everything towers approach black, reading as a silhouette
- The kill zone of a maze is literally the darkest region of the screen
- Spectating an opponent's maze reveals their strategy instantly from across the map
- Tower-zone synergy is visible: a red (damage-built) tower on a red (damage zone) reads as obvious doubling-down

Color modulation is load-bearing for the game's information architecture. It is not polish to add later.

### Selling

Towers are atomic. The player cannot degrade upgrades, cannot sell individual upgrades, cannot partially refund. Selling a tower refunds **30% of total gold invested**, including the base placement cost and all upgrade tiers.

---

## Mobs

There is exactly one mob type in the game.

Each round, a fixed-size train of mobs spawns at the map's entry point. The train walks in a line toward the exit, passing through each required checkpoint in order.

When a mob is killed, it explodes in place and instantly respawns at that location, continuing along the train's path. The train never stops.

The round ends when the entire train has exited the map.

**Mob HP scales between rounds.** Working curve: flat for rounds 1-5, then approximately ×1.12/round. This is a global constant, not a per-map variable. Mob count per round (Enemy Supply) is a per-map variable and does not change round-to-round. Mob speed is constant.

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

**Kills** — 1 gold per mob killed during the run phase. Because mobs respawn infinitely, kill income scales with tower DPS.

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

### No mid-match shake-ups

No random events, no special waves, no armor-resistance mobs. Every round is mechanically the same except for mob HP and the player's evolved maze.

---

## Anti-goals

What this game is explicitly NOT:

- **Not a survival TD.** No "don't let any mobs through" mode.
- **Not a mob-variety TD.** One mob type. Forever.
- **Not a tower-variety TD.** One tower type. Forever.
- **Not an RNG TD.** No surprise waves, no random events mid-match. The map is randomized at start; the match is not.
- **Not a free-flexible upgrade TD.** Towers are atomic.
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
