# State — Wend
Last updated: 2026-06-10

## Current focus
S1 cosmetic implementation (CC). Boards, ranked rename, apply-skins-in-match, the
**Suburbia obstacle library**, and the **FX hook system + flagship fireball** are **done**;
what's left is wiring the remaining `fx_*` art and frames/banners.

## ⏭ NEXT UP (start here next chat)
S1 implementation, remaining phases:
1. **Remaining FX art (②)** — hook system + **fireball + ice** shipped (`projectile_fx.gd`); impact
   is **on-kill-only + subtle** (small/translucent — playtest-tuned). Each remaining catalog `fx_*`
   just needs its art mapped in `ProjectileFX.config_for`: impact-only for `fx_blue_impact`/
   `fx_smoke_ring`/`fx_explosion`; `fx_lightning` body; `fx_dark` recolor. **`fx_fire_trail` needs a
   NEW trail hook** (not yet built — a fading streak behind the projectile). Some need art not yet
   sourced (smoke ring / explosion / lightning). `fx_gold_bolt` stays a tinted arrow (by design).
2. **Frames/banners (⑥)** — author from the owned Wood-UI kit (single-hue outline art).
- **Parked/flagged:** **FX Collection icons** show flat tint swatches, not representative art —
  do as ONE pass once all `fx_*` are wired (gated on the art existing); clean impl = `_item_art`
  pulls a frame from `ProjectileFX.config_for(id)` so each FX self-illustrates (icon shares the
  in-match source). zone tint in-match (clashes with type-color legibility — design call);
  mob recolors (no-tint-painted-sprite rule conflict); aquatic-mob perspective check; Beach
  T17 **BLOCKED** on Tiki art upload. Full detail: `notes/open_items.md` "S1 cosmetic sourcing".

## Last session (2026-06-10, CC — S1 obstacles + FX fireball/ice)
- **Suburbia obstacle library (③) shipped.** Decoupled obstacle ART from the seed: the generator
  now bakes only the blocking footprint (empty `prop_id`); art is resolved LOCALLY per equipped
  board by `ObstacleProps.art_for(board, footprint, cell_key)`. `obstacle_props.gd` reorganised into
  per-board pools (default urban-decay + new SUBURBIA: 18×1×1 greenery/clutter, slide 1×2, pond 2×2);
  20 props extracted to `src/assets/environment/suburbia/`. `map_loader._setup_obstacles` threads the
  local `board_id` + resolves art; authored `.tres` prop_id still wins. sim_harness all-5 green
  (dmg shifted 54985→67903 as the seed-777 layout changed; live==resim holds), cosmetics green, and
  the Suburbia board renders bushes/chairs (was grey rubble) in a real M1 shot. **Render-unverified:**
  slide (1×2) + pond (2×2) only spawn on generated maps — footprints exercised by sim_harness, not yet seen.
- **FX hook system + flagship fireball (②) shipped.** `projectile_fx.gd` resolves the equipped "proj"
  id to body/impact hooks (LOCAL board only, render-only — opponents/resim get the plain arrow, so
  determinism is untouched). `fx_fireball` = animated fireball body (replaces the arrow, sized to its
  ~28px footprint, same speed) + a short impact burst on hit; crits keep the gold arrow tell (no FX).
  Threaded `fx_id` map_loader→build_controller→tower→projectile alongside `proj_tint`. 6 fireball
  frames in `src/assets/fx/fireball/`. **Ice (`fx_ice_spell`) wired too**: directional shard body
  (faces travel via per-art `face_offset`) + subtle on-kill shatter; frames in `src/assets/fx/ice/`.
  Impact tuned to **on-kill-only + small + translucent** after playtest (per-hit bursts occluded the
  mob). Skinned tower bodies no longer aim-rotate (crystals are radial). Dev: **F10** (global,
  debug-only) unlocks all cosmetics for testing. Verified: `fx_smoke` + sim_harness (67903) +
  cosmetics green. Other `fx_*` still tint-only arrows.

## Prior session (2026-06-10, CC — S1 implementation)
Three phases shipped (commits `03b9aae` → `5c563b0`, pushed):
- **Boards:** Suburbia red-brick (T26, retag from toy-brick) + Forest baked pine recolor (T8);
  obstacle determinism gate **verified cleared** (whole map incl. obstacles derives from one
  shared host seed; resim rebuilds from `record[seed]`). Beach still blocked.
- **Ranked rename:** Stone/Bronze/Silver/Gold/Masters — pure positional relabel, ladder math
  unchanged; all 4 ranked test suites + 5 docs updated; promoted to `decisions.md`.
- **Apply skins in match (⑤ complete for art-in-hand):** board biome + tower body + projectile
  tint, **local board only** (opponents default; nothing routes through the match record).
  Shared resolver `CosmeticsCatalog.texture_for/tint_for`. Verified in real M1 matches via the
  reusable `match_shot.tscn` harness; sim_harness round-trip + determinism green.

## Earlier session (2026-06-10, design)
Audited the full S1 asset list section by section against top-down + the *real* board model:
- **Board architecture corrected:** the path is a procedural Line2D (`road_renderer.gd`); the ground
  is a swappable tiling texture (`map_loader.gd`). Boards need **no matched path tiles** — any
  seamless top-down ground that contrasts the path works. Boards reclassified scarce → abundant.
  Captured in `notes/board_obstacle_model.md` (NEW).
- **Obstacles reclassified:** they **block** (sim, not cosmetic), "random in MP." Design rule:
  positions + footprints on one deterministic resim-fed seed; art free over a fixed footprint.
- **Suburbia mega pack purchased ($19.95):** Tier 26 board ground (replaces dead toy-brick) **+** its
  obstacle pool. Retag `board_toybrick` → `board_suburbia`.
- **Membership lapsed → all GDS full price.** Re-sourced the track to owned + recolors → the track
  itself ships at **$0**; only Suburbia + two bespoke milestone FX (ice/fireball) are bought.
- **Ranked tiers renamed** Stone/Bronze/Silver/Gold/Masters (pure rename, ladder math unchanged);
  League badges → tier emblems; medals cut; UI kits → build material (frames/banners authored from
  owned Wood-UI).
- Aquatic mobs (fish/starfish/hammerhead, T6/16/27) confirmed **owned**; perspective check pending.

## Other open threads (not the immediate next step — see NEXT UP above)
- **Steam (blocked on verification):** clears → create Wend App ID → create Playtest app
  (confidential/friends-only; hidden page, manual keys). Confirm entity type at registration.
- **Design (own session):** finalize season-pass absolute threshold integers once playtest data
  exists (`notes/season_pass.md`).

## Recently touched files (this CC session)
- `src/scripts/cosmetics_catalog.gd` — `board_suburbia`/`board_forest` art; prestige rename (Stone↔Platinum); `texture_for`/`tint_for` resolvers
- `src/scripts/map_loader.gd` — equipped board/tower/proj applied for `is_local`; `collection.gd` — DRY resolver
- `src/scripts/{tower,build_controller,projectile}.gd` — tower body skin + projectile tint plumbing
- `src/scripts/leaderboard_service.gd` / `leaderboard_browse.gd` — ranked band rename
- `src/assets/maps/{suburbia,forest}_tile.png` (NEW) · `src/tools/match_shot.*` (NEW reusable in-match shot harness)
- tests updated green: `leaderboard` · `ranked_lp` · `nakama_backend` · `cosmetics` · `sim_harness`
- docs: `notes/{open_items,decisions,pvp_ladder,leaderboard_schema,leaderboard_ui_spec,multiplayer_architecture}.md`, `design/DESIGN_MODES.md`

## Open questions / blocked on
- **Steam:** identity verification pending (2–7 biz days from 2026-06-07). Confirm entity type.
- **Aquatic-mob perspective** — fish/starfish/hammerhead read on a top-down board? CC render check.
- **Absolute task thresholds** (the X integers) — playtest-gated.
- Full open backlog in `notes/open_items.md`.
