# State — Wend
Last updated: 2026-06-23

## Current focus
S1 cosmetic implementation (CC): boards, ranked rename, apply-skins-in-match, Suburbia obstacles,
full FX track (8, real art), frames/banners (wood 9-patch tinted), the **Season Tasks panel**
(XP-earn surface), and the **post-match season nudge** all implemented. Remaining: judgment/tuning
passes (FX facings/sizes, frames/banners proportions) + Beach (needs a top-down sand tile).

## ⏭ NEXT UP (start here next chat)
**S1 is feature-complete — remaining is ONE test + tuning pass** (user runs everything through the
motions, then hands back a consolidated tweak list). No new features below; these are the dials:
1. **FX (②) — ALL 8 wired with real art** (`projectile_fx.gd`). Bodies: fireball (T10), arcane-bolt
   (T14), ice (T20), lightning (T24), dark (T30, recoloured orb). Impacts (on-kill, subtle):
   blue-impact (T9), smoke-ring (T18), explosion (T29). gold-bolt (T4) = tinted arrow by design.
   Art from the fireball/ice packs + **towers.zip** (cannon explode + smoke-ring sheet, tesla
   electric, magic projectiles). Hooks: body / impact (animated OR single-frame burst) / trail
   (built, currently unused). FX **Collection icons self-illustrate** now (`_item_art` pulls a frame
   from `ProjectileFX.icon_frame`). **Remaining FX work is judgment-only — a single playtest tuning
   pass:** sizes/alpha/facing per FX (arcane-bolt & lightning `face_offset` are guesses; lightning/
   dark recolor look; smoke-ring/explosion burst size). Not a per-item loop — review all at once.
2. **Frames/banners (⑥) — first pass shipped.** Wood-UI kit as `StyleBoxTexture` 9-patch, recoloured
   per item (one frame shape `frame_panel.png` behind the avatar, one banner shape `banner_plank.png`
   as the card bg; `_wood_box` in `collection.gd`). All catalog frame/banner tints drive it incl.
   prestige (tinted wood, not true metal — flag if that's not acceptable). **Tuning open:** avatar
   frame reads small + the banner plank is a large empty expanse (card is wide); prestige metal look;
   maybe a `panel_headboards` arched banner instead of a plank. Verify via `collection_shot.tscn`.
- **Parked/flagged:** zone tint in-match (clashes with type-color legibility — design call);
  mob recolors (no-tint-painted-sprite rule conflict); aquatic-mob perspective check. **Beach T17
  STILL BLOCKED:** the uploaded `Tikibeachshopgameassetpack` is **side-view shop art** (walls/shelves/
  horizon backdrop), NOT a top-down tileable sand ground — unusable for the board (verified the bg +
  sand_piece). Beach needs a real top-down seamless sand tile. Full detail: `notes/open_items.md`.

## Last session (2026-06-23 pt.2, CC — steam_auth 500 fixed & live, 1×4 pillar, quit-freeze fix)
- **steam_auth E2E now works.** Root cause: the `steam_auth` RPC called
  `nk.authenticateCustom("steam:"+id, null, true)` — Nakama's JS runtime only skips the username
  arg when it's `undefined`, so `null` threw `TypeError: expects string` → HTTP 500 on EVERY Steam
  login → client fell back to device auth → leaderboards showed the auto-handle (`OJglnHpFjH`) not
  the persona. Fixed `null`→`undefined` (`deploy/nakama/data/modules/index.js:236`), **deployed to
  the box + nakama restarted** (backup at `index.js.bak.preauthfix`). User confirmed "Irish Whiskey"
  now shows on the board. NOTE: the fix is client-agnostic — no Steam re-upload needed.
- **Tall ruin pillar is a real 1×4 blocker** (was 1×2; towers sat on its ~1.8-cell overhang —
  the "tall white rock" bug). `building_ruin_11`→footprint 1×4; `pick_footprint` bakes a rare 1×4
  when `remaining≥4` (same single rng draw + same 1×1/1×2 bands → maps with <4 budget generate
  byte-identically, incl. seed-777 harness=67903); `art_for` degrades a 1×4 within the board's own
  theme so Suburbia draws its slide, not an urban pillar. sim_harness ✅, gen+art check ✅ (41 pillars).
- **Quit-to-menu freeze + "Lambda capture freed" errors fixed.** `leaderboard_panel.gd` connected
  capturing lambdas to coordinator signals (fired on a freed self during teardown) → swapped to
  `_refresh.unbind(1)` (auto-disconnected). `match_end_panel.gd` `_show_medal`/`_populate_placement`
  kept building UI after their awaits (chunked re-sim + network fetch) on a freed panel → added
  `is_instance_valid(self)` guards. Full reimport clean; sim_harness ✅.
- **Steam upload kicks the desktop client offline** (the original "Disconnected"): SteamCMD logs in
  with the personal account → same-account single-session limit boots the client. **TODO tomorrow:**
  dedicated builder account (Edit App Metadata + Publish only) + README §3 → `+login wend_builder`.
  Detail: memory `wend-steam-builder-account`. Account creation/permissions are user-only.
- **Uncommitted** (3 fixes): `index.js` (live on box) · `obstacle_props.gd`+`map_generator.gd` ·
  `leaderboard_panel.gd`+`match_end_panel.gd`.

## Prior session (2026-06-23, CC — Steam: build submitted, GodotSteam SDK, Steam→Nakama auth, match-end fixes)
- **Steam build gate CLEARED.** Windows export preset added (x86_64, separate `.pck`); Playtest
  **build + store page both submitted for review** (Jun 22, in queue). `steamcmd` + depot/app_build
  VDFs (depot **4884651**) + `deploy/steam/README.md`. Confidential internal beta — store page stays
  **HIDDEN by choice for now** (the 2-week "Coming Soon" clock is deliberately not started; 21-day
  app-credit gate ~mid-July). No GodotSteam needed to pass review, but integrated anyway (below).
- **GodotSteam GDExtension 4.19.1 integrated** (`src/addons/godotsteam/`, **gitignored as an external
  dep** — fetch per `deploy/steam/STEAM_SDK.md`). `SteamManager` autoload: init + per-frame callbacks
  + graceful no-Steam fallback + overlay + identity. **Overlay verified working** in the Steam build.
- **Steam→Nakama auth = custom RPC.** Built-in `authenticateSteam` can't validate SDK 1.57+ web-API
  tickets (omits the required `identity`), so `steam_auth` RPC (index.js) validates WITH identity +
  mints a session; persona → account `display_name` → shown on leaderboards. `connect_backend` now
  **prefers Steam over a stale device session**. Publisher key in box `.env`; index.js deployed +
  nakama restarted. ⏳ verify E2E on an online Steam-launched client (`steam_auth ok` in nakama logs).
- **Match-end freeze fixed.** Authoritative re-sim ran synchronously on the main thread (node-based,
  can't thread) → froze the results screen. `ResimScript.run` now **chunks across frames**
  (`ticks_per_frame`); `_authoritative_score`/`report_match_result`/`leave_match_to_home` async; panel
  renders first. `sim_harness` verifies **chunked==live (67903)** + round-trip/serialize/legality/reject.
- Pushed `0247b74` (SDK + tooling) and `3a0266f` (auth + freeze). **Next:** re-upload the A+B build to
  Steam + set live; verify steam_auth E2E; rotate exposed secrets (done); Apple enrollment in progress
  (Mac export/depot later). Full Steam detail: `deploy/steam/STEAM_SDK.md`.

## Prior session (2026-06-10, CC — S1 feature-complete: obstacles · full FX track · frames/banners · season task UI)
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
  cosmetics green.
- **Full FX track wired (②).** All 8 `fx_*` mapped to hooks in `ProjectileFX.config_for`: bodies
  fireball/arcane-bolt/ice/lightning/dark, impacts blue/smoke-ring/explosion (on-kill, subtle).
  `fx_fire_trail` cut (read identical to fireball) → T14 = `fx_arcane_bolt` (towers.zip magic bolt).
  Art from the fireball/ice packs + towers.zip (cannon explode + smoke-ring sheet, tesla electric,
  magic projectiles). Collection FX icons self-illustrate via `ProjectileFX.icon_frame`. Trail hook
  built but currently unused. (gold-bolt stays a tinted arrow by design.)
- **Frames/banners (⑥) first pass.** Wood-UI `StyleBoxTexture` 9-patch, tinted per item (`_wood_box`
  in `collection.gd`); covers prestige via tint (not true metal — flagged).
- **Season Tasks panel + post-match nudge.** The XP earn loop was already wired (`scene_manager` →
  `TaskCatalog.record_match`) but INVISIBLE — added the Season-screen Rewards/Tasks toggle (15 tasks +
  progress + payouts) and a "+N season XP" end-panel chip (`match_end_panel._show_season_award` from
  `SceneManager.last_task_award`, Trials + Ranked only).
- **Beach (T17) confirmed still blocked** — the uploaded Tiki pack is side-view shop art, not a
  top-down sand ground (verified). Needs a real seamless top-down sand tile.
- Dev shot harnesses added: `collection_shot` · `season_shot` · `nudge_shot` (alongside `match_shot`).

## Earlier session (2026-06-10, CC — S1 implementation)
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

## Other open threads (not the immediate next step — see NEXT UP above)
- **Steam (build in review):** Playtest build + store page submitted Jun 22 (3–5 biz days). SDK
  integrated + backend `steam_auth` deployed. Remaining: re-upload the A+B build + set live; verify
  `steam_auth` E2E on an online Steam-launched client; decide when to flip the store page to public
  "Coming Soon" (gates earliest release: 2-week visible + 21-day credit ~mid-July). Detail: `deploy/steam/STEAM_SDK.md`.
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
- **Steam:** verify `steam_auth` end-to-end — online, Steam-launched build → `steam_auth ok` in nakama logs + real persona name on the board.
- **Aquatic-mob perspective** — fish/starfish/hammerhead read on a top-down board? CC render check.
- **Absolute task thresholds** (the X integers) — playtest-gated.
- Full open backlog in `notes/open_items.md`.
