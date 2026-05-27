# State

Last updated: 2026-05-26

---

## Current focus

Prototype implementation underway in Godot 4.6.3. Core gameplay loop (mob train + tower placement + upgrades) is playable. Mechanics still incomplete; rounds, gold, and several upgrade stats not yet wired.

---

## Last session — 2026-05-26 (prototype kickoff)

First implementation session. Switched from design Claude to Claude Code. Brought up the Godot project from scratch through to a playable interactive prototype.

What landed:

- **Godot 4.6.3 project at `src/`** — viewport 1920×1080, GL Compatibility renderer, `prototype.tscn` set as main scene
- **Asset pack imported and curated** — full pack lives in `art/` (gitignored). Pulled `arrow_box` tower sprites, `zombie_01` walk_2 + die + base frames, summer grass + path tilesheet, and two level markers into `src/assets/`
- **Core loop scene** — flat green background, V-shape path (Line2D) with checkpoint marker at the apex
- **Mob (`mob.gd`)** — `zombie_01` AnimatedSprite2D, walks the path at constant speed, head rotates to lead direction, dies + respawns in place on hit, despawns at exit
- **Spawner (`spawner.gd`)** — emits N mobs at fixed interval (currently 8 mobs, 1.5s apart, 0.5s initial delay). User-locked rule: always use a spawner pattern, never hardcode multiple mob instances
- **Tower (`tower.gd`)** — `arrow_box` sprite, scans `mobs` array each frame for furthest-along walking mob in range, rotates body to face current target, fires arrow projectile on cooldown, brief loaded/unloaded sprite swap on fire
- **Projectile (`projectile.gd`)** — flies toward target at 900px/sec, head-first, calls `take_hit` and despawns on arrival
- **Build controller (`build_controller.gd`)** — owns placement UX. Ghost preview + range circle tracks mouse in build mode. Green/red tint by validity (distance from path + spacing from other towers). Hint label at top-left shows current controls. **Hotkeys**: B = toggle build mode, Esc = exit mode / close panel
- **Tower upgrades (`upgrade_panel.gd`)** — left-click on a placed tower opens a 6-stat upgrade panel anchored next to it (damage, range, atk speed, crit chance, crit damage, multishot). Each + button increments that stat's tier
- **Color modulation** — tower sprite tints toward stat hues as tiers accumulate (red=damage, green=range, blue=atk speed, yellow=crit chance, orange=crit damage, purple=multishot). Math is complementary RGB subtraction per tier: max one stat → vivid hue, max everything → approaches black. DESIGN flagged this as load-bearing for information architecture
- **Mechanically wired**: damage (+10%/tier), range (+10%/tier, also resizes the selected-tower range circle), attack speed (-cooldown +10%/tier)
- **Tracked but not yet mechanically applied**: crit chance, crit damage, multishot — visible in panel and modulating color, but tower still fires single non-crit projectile regardless

What was debugged and resolved:

- **Embedded Game tab mouse offset (Godot 4.5+)** — clicks landed ~10px below visible cursor because the embedded Game tab's toolbar isn't subtracted from reported mouse Y. Diagnosed by instrumentation (live position readout + click markers + environment dump). **Fix**: in the Game tab's menu, uncheck **"Embed Game on Next Play"**. Memory saved as `reference_godot_embedded_game_offset` for future Godot sessions.

Files produced this session:

- `src/project.godot`, `src/.gitignore`
- `src/scenes/prototype.tscn`
- `src/scripts/main.gd`, `mob.gd`, `tower.gd`, `projectile.gd`, `spawner.gd`, `build_controller.gd`, `upgrade_panel.gd`
- `src/assets/towers/` (3 arrow_box sprites)
- `src/assets/mobs/` (21 zombie_01 frames: base + walk_2 + die)
- `src/assets/maps/` (summer tilesheet + grass + 2 level markers)
- `.gitignore` (root)
- Updated `PROJECT.md`, this `STATE.md`

---

## Next step

Pick one on next session start:

1. **Wire the remaining upgrade mechanics** (recommended) — multishot fires (1 + N) projectiles at the front N mobs; crit chance rolls per shot; crit damage multiplies on crit. Closes the upgrade slice mechanically.
2. **Round structure** — build phase / run phase state machine, round counter, gold trickling in (round bonus + kill bonus + interest). Sets up the actual game economy. Needed before tower upgrades have meaningful cost.
3. **Background tiles** — replace the flat green + Line2D path with the `summer_grass_path.png` tilesheet. Pure visual polish.
4. **Multiple checkpoints** — extend the path with 2–3 turns, level markers at each. Enables more interesting maze geometry once placement is grid-snapped.

Recommended order: 1 → 2 → 3 → 4.

---

## Recently touched files

See "Files produced this session" above.

---

## Open questions / blocked on

Carried over from the design phase; many will resolve through prototyping.

### Upgrade mechanics not yet wired
- **Multishot** — locked at +N targets per attack, hard cap 2–3 TBD. Implementation: tower fires multiple projectiles, each targets a different mob ordered by path progress
- **Crit chance** — per-shot roll. Working: +10%/tier, soft cap 75% TBD
- **Crit damage** — multiplier on crit hits. Working: base 1.5×, +20%/tier, soft cap 500% TBD
- **Tier costs** — currently free (no gold system). Layer in with round structure

### Bonus zones
- Magnitude/size interpolation curve (linear vs non-linear, exact floor/ceiling values per type)
- Full type set beyond "damage" and "slow" — attack speed, crit, multishot, range (set of 6 implied)
- Color assignments per zone type
- Map procgen reachability constraint algorithm
- Maximum zone count per map (working assumption: 5–6)
- Map grid dimensions for MP (working assumption: ~30×30 to 40×40)

### Tower upgrades
- Tier costs per upgrade (cost curve)
- Soft/hard caps per stat: multishot 2–3, crit chance ≤75–100%, crit damage ~500%, attack speed/range soft caps, damage uncapped
- Six specialization milestone effects (heavy shot, sniper, frenzy, lucky streak, devastator, spread) — all placeholder, need real design
- Specialization trigger threshold (working: ~level 15 cumulative)

### Wave structure
- HP scaling curve shape (working: flat rounds 1–5, exponential ~1.10–1.15/round after)
- Build phase timer per round (working: 30s round 1, 25s rounds 2–29, 5–10s round 30+)
- Mob train length per map (Enemy Supply — map variable, ranges TBD)

### Multiplayer
- Hosting model (P2P vs $5–20/mo VPS vs Steam Networking) — explicitly tabled
- Asynchronous round handling: spectate-while-waiting flow (noted as expected solution but unspec'd)
- ELO/ranking math
- Cross-platform identity / friends system — tabled
- Behavior on player leave mid-match: maze freezes vs vanishes vs ghost-visible

### Campaign
- Mission count (Random TD had ~20, AMazing TD shipped 19, working assumption: 20–30)
- Difficulty curve / what each mission teaches
- Bronze/silver/gold thresholds methodology

### Bots
- Damage-curve approach (Easy ~60% optimal, Hard ~95%, Nightmare ~105%)
- Do bots actually build mazes visibly, or just produce damage numbers?
- How bot kill counts feed into life-transfer math

### Guilds
- Phase 2 — entire system deferred until core game ships

### Platform & art
- Platform phasing (working assumption: PC/Mac first, console/mobile later)
- Tower visual identity once art is final — currently using the third-party `arrow_box` placeholder
- Color modulation calibration — current K=0.07 per tier with 14-tier soft target. Playtest may want different curve

### Risks flagged but not solved
- Leader snowball in MP (Model B pairwise less prone than Model A average-based, but still real)
- Color-blind accessibility for color-coded zones and tower modulation
- Mobile UX for tower placement and zone identification on small screens
- The competitor's failure modes (art, dead MP, regression) — staying aware of these throughout development

---

## Reference: locked design decisions

See `DESIGN.md` for the full locked design. Decisions there don't get re-litigated without explicit reopening.
