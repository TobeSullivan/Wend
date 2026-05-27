# Design

Locked design decisions for the game. Anything in this document is settled and not re-litigated without explicit reopening. Open questions live in `STATE.md`, not here.

---

## Pillars

The design rests on four pillars. Every other decision serves these.

**Simple to learn, hard to master.** One tower type, one mob type. The entire vocabulary of the game can be taught in five minutes. Mastery comes from reading geometry, identifying optimal placement, and committing to specialization — not from memorizing tower charts or wave compositions.

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

**Build phase (timed).** Player places towers, upgrades existing towers, sells towers. Other players' actions are hidden during this phase.

**Run phase (untimed).** A train of mobs spawns at the map's entry point and walks to the exit, hitting required checkpoints in order. Towers fire automatically. Mobs explode and respawn in place when killed. The run phase ends when all mobs in the train have exited the map. During this phase, the player can watch their own maze run, OR click any other player's name to watch theirs instead.

After run phase ends, lives transfer between players based on kill differences (multiplayer only), then the next build phase begins.

---

## Towers

There is exactly one tower type in the game.

Towers fire automatically at the front of the mob train within range. Default targeting is first-in-line (mob nearest to exit, within range). Targeting behavior is not player-configurable at launch.

### Upgrade stats (six)

A tower can be upgraded across six independent stats. The player buys tiers of each stat freely; no branching, no exclusion. Upgrade costs scale per tier.

The six stats:

- **Damage** — flat damage per hit. Effectively uncapped; cost makes high tiers impractical.
- **Range** — how far the tower can reach. Soft-capped at a level where additional range serves no practical use given map dimensions.
- **Attack Speed** — hits per second. Soft-capped; at the cap, further investment rounds to zero and the UI reads "MAX."
- **Crit Chance** — percentage of hits that crit. Hard-capped at a value below 100% (working number 75%, TBD) so non-crits still happen.
- **Crit Damage** — multiplier on crit hits. Hard-capped (working ~500%, TBD).
- **Multishot** — additional targets per attack. Hard-capped at 2 or 3 (TBD).

### Architecture: hybrid with emergent specialization

The tower upgrade system is free-form across the six stats, but a **specialization milestone** triggers when a tower has accumulated enough total upgrades. Whichever stat the tower has the most tiers invested in determines which specialization unlocks. Specializations grant a powerful unique passive effect — e.g. crit-focused towers get chained crits, multishot-focused towers get bonus damage per target, etc. Exact effects are open in `STATE.md`.

This means specialization emerges from play rather than being chosen up front. A tower's identity is a consequence of what the player bought, which is itself a consequence of where the tower was placed and which bonus zones it sits on.

### Color modulation (visual identity)

A tower's visual color encodes its upgrade state at a glance. Each stat has a color assignment (working: damage = red, attack speed = blue, crit chance = yellow, crit damage = orange, range = green, multishot = purple — TBD). As the tower accumulates tiers in a stat, its color shifts toward that stat's hue. Multiple investments blend like physical paint.

Consequences of this system, all intentional:

- Pale towers are visibly under-invested
- Vivid mid-tones mean a tower is specialized in one or two directions
- Maxed-everything towers approach black, reading as a silhouette
- The "kill zone" of a maze is literally the darkest region of the screen
- Spectating an opponent's maze reveals their strategy instantly from across the map
- Tower-zone synergy is visible: a red (damage-built) tower on a red (damage zone) reads as obvious doubling-down

Color modulation is load-bearing for the game's information architecture. It is not "polish to add later."

### Selling

Towers are atomic. The player cannot degrade upgrades, cannot sell individual upgrades, cannot partially refund. Selling a tower refunds **30% of total gold invested in that tower**, including the base placement cost and all upgrade tiers.

The 30% rate is intentionally painful. Selling a 1200-gold maxed tower returns 360 gold. The sunk cost is real and visible (via the dark color of a built-up tower). The player feels the loss when pivoting.

---

## Mobs

There is exactly one mob type in the game.

Each round, a fixed-size train of mobs spawns at the map's entry point. The train walks in a line toward the exit, passing through each required checkpoint in order.

When a mob is killed, it explodes in place (visual effect — explosion animation) and instantly respawns at that location, continuing along the train's path. From the player's perspective, the train never stops; mobs flash and reset visually, but the train marches on.

The round ends when the entire train has exited the map.

Mob HP scales between rounds (curve TBD in `STATE.md`). Mob count per round (Enemy Supply) is a per-map variable and does not change round-to-round within a match. Mob speed is constant — does not scale within a match.

---

## Maps

Every map has the following variables that define its character:

- **Points** — how many checkpoints (1-3) the mob train must hit before exiting
- **Supply** — how many towers the player can place
- **Enemy Supply** — how many mobs per train
- **Bonus Zone Count** — how many zones exist on the map
- **Bonus Zone Types** — which types are present (subset of the full type set)
- **Bonus Zone Magnitudes** — rolled per zone within type-specific floor/ceiling bands

**Multiplayer maps are always the same size.** Map grid dimensions for MP are TBD (working assumption ~30x30 to 40x40 tiles).

Single-player maps are hand-designed; the variables above are set deliberately to teach specific lessons.

Multiplayer maps are procedurally generated from a seed. Procgen must guarantee:

- At least one bonus zone is reachable given the tower supply
- No more than two zones overlap at any point
- Path from entry through all checkpoints to exit is always solvable

Procgen algorithm details TBD in `STATE.md`.

---

## Bonus zones

Bonus zones are colored circles painted on the map. A tower whose footprint **touches** a zone receives that zone's bonus. Partial overlap is sufficient; the tower does not need to be fully inside.

### Type set

Zones come in two functional categories:

- **Tower buffs** — apply to towers placed in the zone. Examples: damage, range, attack speed, crit chance, crit damage, multishot.
- **Mob debuffs** — apply to mobs walking through the zone. Example: slow.

Both categories exist at launch. The full type set is TBD in `STATE.md`.

### Visual encoding

All zones are circles. Each type has a distinct color. Overlapping zones blend visually like color mixing (red damage + blue slow = purple in the overlap region). This means a player can read map state at a glance: solid color = single zone, blended color = overlap region, color identifies the type(s).

If type-specific shapes are added later (e.g. squares for one type, circles for another), that's a Phase 2 visual upgrade and does not change the math.

### Magnitude/size relationship

Zone magnitude (the strength of the bonus) is inversely proportional to size. A 10% damage zone might be 10x10 tiles wide. A 100% damage zone might be 2x2. The procgen rolls a magnitude within type-specific floor/ceiling bands, and zone size falls out of the formula.

This is a built-in balance mechanism — there is no objectively best zone type to seek out, only different effort-vs-payoff tradeoffs. Reaching a far-away high-magnitude zone may be worth more than placing many towers on a nearby low-magnitude zone, or it may not — depends on supply, distance, and other zone placements.

Magnitudes are stepped in 10% increments. No decimals, no continuous values. A zone rolls as 10%, 20%, 30%, ..., 100%.

The interpolation curve between magnitude and size (linear, non-linear, etc.) is TBD.

### Stacking

A tower benefiting from two zones of the same type gets both bonuses added together (e.g. tower on a 30% damage zone overlapping a 40% damage zone gets +70% damage). Different-type zones apply independently.

Procgen guarantees no more than two zones overlap at any point on the map. The two-overlap cap prevents degenerate "tower of god" seeds and makes balance tractable.

---

## Economy

Each player's gold income each round comes from three sources:

**Round bonus** — flat gold per round completion. Exact amount TBD.

**Kills** — gold per mob killed during the run phase. Exact amount TBD. Note: because mobs respawn infinitely within a round, kill income scales with tower DPS, not with mob count.

**Interest** — 1 gold per 10 gold currently saved, awarded at round end. Capped at 50 gold per round (i.e. interest scales until the player has 500 saved, then flatlines).

The interest mechanic creates a strategic tension between spending early (more towers/upgrades sooner) and saving early (more compounding income later). Cap prevents whales from runaway snowball.

---

## Pathing

Mobs always take the shortest path from current position to the next required checkpoint, in order (entry → 1 → 2 → 3 → exit). The pathfinder treats placed towers as walls.

**Towers cannot be placed if they would fully block the path** to any required checkpoint. The placement system rejects invalid positions.

Path is recalculated at the start of each round only. **Towers cannot be added, removed, sold, or upgraded during the run phase.** All maze changes happen during the build phase.

---

## Single-player

Single-player is a series of scripted, hand-designed campaign missions. Each mission has fixed mob counts, fixed checkpoints, fixed bonus zones — no randomization. The player builds the best maze they can to "solve the puzzle."

The win condition is hitting a damage threshold. Each mission has three thresholds:

- **Bronze** — achievable by casual play
- **Silver** — requires reasonable optimization
- **Gold** — requires strong understanding of the system

Bronze is the bar for "beating the level." Silver and gold are for engaged players. Leaderboard rankings are for the dedicated.

**There are no lives in single-player.** Mobs that exit don't punish the player. The match ends when the player declares it done, or when a soft-cap structure (TBD) wraps up the mission. The leaderboard score is total damage dealt.

Single-player does not show other players' mazes. It is a solo puzzle. Leaderboard comparisons happen only post-match.

---

## Multiplayer

Two lobby modes:

**Ranked.** Always 8 players. No invites, no friends. Real humans only. Matchmaking populates the lobby. If player population is too low at launch, ranked may fall back to 6 or 4 — but with the same no-invite restriction. ELO/ranking math TBD.

**Private.** Any size from 1v1 up to 8 total. Players can fill remaining seats with bots at chosen difficulty. Private matches don't affect ranked rating.

### Lives system

Each player starts with 100 lives. After each run phase, lives transfer based on **Model B (pairwise transfers)**: for each opponent, the difference in kills that round transfers as lives. A player who out-killed every opponent by 5 in an 8-player match gains 35 lives that round (5 × 7 opponents); each opponent loses 5.

The total life pool is constant at 800 (8 × 100). Lives are zero-sum.

**Transfers start at full strength from round 1.** No dampening. A player who fails to build in early rounds loses lives immediately — this prevents a no-build savings meta from emerging.

### Hybrid elimination

A player at 0 lives is out of the match. They can leave immediately with no penalty and requeue for a new match, or stay and spectate. The match continues until either one player remains or a soft cap is reached.

When a player leaves mid-match, their maze handling (freeze in place, vanish, ghost visible) is TBD in `STATE.md`.

### Visibility

During build phase, all players' mazes are hidden from each other.

During run phase, the player can watch their own maze OR click any other player's name to watch theirs. Only one maze is visible at a time. Switching is free during the run.

A player who finishes their run phase early (shorter maze = faster traversal) can spectate other players' ongoing runs while waiting. Since all players have the same supply cap, maze lengths converge in practice; spectating dead time is expected to be small.

### Bot opponents

Bots in private lobbies produce damage curves rather than playing the game per se. Bot difficulty determines what fraction of optimal damage the bot achieves on a given seed:

- Easy: ~60% of optimal
- Medium: ~80%
- Hard: ~95%
- Nightmare: ~105% (beats most humans)

Whether bots actually build a visible maze or whether they're abstract score-generators is TBD in `STATE.md`. Bot kill counts feed into the same life-transfer pool as human kills.

---

## Wave structure

A multiplayer match progresses through rounds. There is no hard match cap. Match end is triggered by hybrid elimination (last player standing).

### Build phase timing

- Round 1: 30 seconds
- Rounds 2 through 29: 25 seconds (working number, tunable)
- Round 30+: compressed to 5-10 seconds (soft cap — encourages match resolution without forcing it)

The compressed late-round timer is a soft pacing tool, not a hard cutoff. Players who haven't finished their maze by round 30 had ample time and now the game encourages closure.

### Run phase timing

Run phases are **untimed**. They end when the mob train fully exits the map. Maze length and tower DPS determine how long this takes.

This creates one of the key design consequences of the game: longer mazes get more time-on-tower per mob, which means more DPS per round. Maze length is a temporal weapon.

### Mob HP scaling

Mob HP scales between rounds. Exact curve TBD in `STATE.md`. Working assumption: roughly flat for the first ~5 rounds (during construction phase when players are still placing towers), then growth of approximately 10-15% per round.

Mob count per round and mob speed do **not** scale within a match.

### No mid-match shake-ups

There are no random events, no special waves, no armor-resistance mobs, no surprise mechanics. The game is purely about how the player builds and upgrades on the seed they were given. Every round is mechanically the same except for mob HP and the player's own evolved maze.

---

## Anti-goals

What this game is explicitly NOT:

- **Not a survival TD.** No "don't let any mobs through" mode. Mobs always exit.
- **Not a mob-variety TD.** One mob type. Forever.
- **Not a tower-variety TD.** One tower type. Forever.
- **Not an RNG TD.** No surprise waves, no random events mid-match, no "this wave is armored." The map is randomized at start; the match is not.
- **Not a free-flexible upgrade TD.** Towers are atomic. No degrading, no upgrade-selling.
- **Not the SC2 map verbatim.** Inspired by Random TD, not legally bound to it. We use the mechanic family freely (mechanics aren't copyrightable). We do not reuse tower names, level names, art style, UI layouts, or specific tuning values from Random TD or AMazing TD.
- **Not Greek-themed.** Art direction is the user's call, but explicitly not the Greek-god aesthetic of AMazing TD.

---

## Out of scope at launch (Phase 2 or later)

These features have been discussed and are deferred:

- **Guilds and guild rankings.** Real retention amplifier but real implementation cost. Tabled until core game ships and a player base exists.
- **Cross-platform play.** Each platform has its own identity layer (Steam, PSN, Xbox Live, Nintendo, Apple, Google). Crossplay requires an account system above all of them. Tabled.
- **Friends features across platforms.** Same problem as crossplay.
- **Console ports.** PC/Mac assumed first. Console certification, dev kits, platform requirements all deferred.
- **Mobile.** Touch UX, smaller screens, and platform identity make this a separate effort. Deferred.
- **Slow zones and other mob-debuff zones beyond launch set.** Will exist at launch, but the launch set is constrained — additional types added in updates.
- **Type-specific zone shapes.** Launch is all-circles. Square/diamond/etc. for specific types is a later visual upgrade.
- **Hosting infrastructure decisions.** P2P vs cheap VPS vs Steam Networking — tabled until netcode design begins.
- **Targeting behavior options.** First-in-line only at launch. Player-configurable targeting (last, strongest, weakest, closest) is a possible later addition.
