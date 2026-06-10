# COSMETICS — cosmetics & collection meta-layer

Locked 2026-06-09. The content model + IA the Collection and Season surfaces hang off.
Screens mocked in `notes/mockups/collection_mock.html` + `season_mock.html`.
Catalogue of available art: `notes/asset_catalog.md` (+ raw `notes/gds_catalog.csv`); buy
list: `notes/asset_buy_list.md`. Season track + XP: `design/SEASON.md` + `notes/task_system.md`.

**Why this is viable solo:** every asset on gamedeveloperstudio.com is one artist, one coherent
style — buy more, it always matches. The single-tower / single-mob pillar becomes the *reason*
cosmetics work: a deliberately spare game earns visual richness through paint, not mechanics.

---

## 3 cardinal rules (these protect the pillars — do not bend)

1. **Cosmetics are 100% visual. Zero gameplay / zero competitive effect.** Footprints stay
   square, hitboxes / ranges / timings unchanged. This is what lets a Ranked game ship skins.
2. **Skins never enter the sim.** Equipped cosmetics are a client render-layer setting — never
   in the input log, never re-simmed. (CC: do not route equipped-skin state through the match
   record, or it breaks determinism / authoritative re-sim.)
3. **Cosmetic FX match the default's silhouette + duration — only the paint changes.** A
   reskinned projectile/impact can't be louder or longer than stock. Board stays calm
   (JUICE guardrail), Ranked stays readable.

---

## The color decision (FINAL — forced by the owned art)

7 distinct owned tower sprites can't coexist with a "pale → vivid → near-black" tower-body
upgrade ramp. So:
- **Tower growth / investment signal lives OFF the body** → a **base aura ring + size step**
  (multishot + fire-rate + the tower info box already carry legibility).
- **The tower body is a pure skin slot.**
- **Zone color is NOT load-bearing as long as the labels stay** → zone recolors are valid.

---

## Runtime tinting rule (how "tier = color" reuse actually works)

Recoloring an asset by tier (bronze/silver/gold/…) is cheap **only on outline / single-hue
art**, and that constraint dictates which slots can do it:

- **Outline / single-hue art** (stickers, zone circles, simple frames/banners, the star/flag
  primitives) → **runtime tint is free.** One shape, a `outline_color` parameter per tier. No
  per-tier asset files. **Masters** is the one special case: an **animated multi-color stroke**
  (shader / animated stroke flag), reused across every shape regardless of which shape it is.
- **Multi-color painted sprites** (towers, mobs, crystals) → **NOT a clean runtime tint.** A
  flat `modulate` over a full-color sprite muddies every color at once. These stay **authored
  recolor variants** (the packs often ship them — the crystal trio *is* three authored recolors)
  or need a palette-swap shader. Treat them as distinct assets, not tints.

Implication: **tier-as-color is a runtime tint, free on outline/single-hue slots only.** This is
exactly why the rank sticker (below) is the perfect Ranked reward.

---

## Supply-driven reward economy (what goes where, and why)

Reward frequency follows **how much of it we have / can renew**. Abundant slots are frequent
commons; scarce slots are weighty milestones.

- **Effectively infinite / renewable each season** (carry the volume): **titles** (just words),
  **zone recolors** (one circle, tinted), **sticker shapes** (a vector outline, authored in
  minutes or pulled from owned art), **mob skins** (Monster Maker generates variants; the
  collections each ship many colors), **FX skins** (the free 15-projectile kit + cheap element
  families). → frequent commons.
- **Moderate** (uncommon, weightier): **board biomes** (high visual impact, more work to adopt),
  **frames / banners** (cut from kits).
- **Scarce / finite** (rare, milestone-grade): **tower skins** (~8 authored, each a hero asset),
  distinctive prestige flair.

**The long-term limiter is the finite slots.** Mob/FX/title/zone/sticker-shape renew at ~zero
cost every season; authored tower skins do not (~8 total). So: **one tower milestone per season**
(the crystal trio covers seasons 1–3), and budget new tower-art purchases as the constraint for
season 4+. The abundant slots fill every other tier.

---

## The equip slots

**In-match** (change the match view):
- **Tower** — body sprite. Default = arrow box (deliberate plain starter so a skin feels like a
  step up). Owned skins: ballista, slingshot, tesla, magic eye, crystal x3, catapult (PNG export
  pending). Crystal trio = the earned/rarity line.
- **Board biome** — surface + grass + path tiles as one themed set. Default = summer grass.
  **Hard filter: path-vs-ground contrast must survive every biome** or maze legibility breaks.
- **Zone** — bonus-zone treatment (labels always stay; recolor only).
- **Projectile + FX** — the shot + its impact, paired. **Themed 1:1 to the tower skins** (fire
  tower → fire shot, tesla → electric shot). Backbone = free "Game projectiles" kit.
- **Mob** — the horde's look. One type mechanically, many paints. Default = undead. Skins must
  match the default silhouette/scale (cardinal rule 3) — single small/mid creatures + recolor
  families; no oversized bosses.
- **Board sticker** — *new slot, see below.* Lives in the board chrome, not on the play surface.

**Profile flair** (your identity card in lobby / leaderboard / result screens):
- **Frame** — border around the (Steam, read-only) avatar.
- **Banner** — background behind your name.
- **Title** — text tag, chosen from an earned list (never free text).

**Identity is from Steam, read-only:** name + avatar come from the Steam persona, never editable.
**Zero UGC anywhere** → Wend never moderates names/images; Valve's moderation is inherited.

---

## Board sticker system (Ranked prestige — new slot)

A break-the-grid cosmetic that turns dead chrome into identity (the JUICE "box overlaps the play
surface" grammar, applied as a flex).

- **Where:** the board *chrome* — the dead margin around the 25×16 grid — overlapping slightly
  onto the right rail / top / left / bottom edges. **Never** over the maze, path, towers, or
  zones. It fills an art gap precisely because it sits where nothing gameplay-relevant is.
- **What a sticker is:** a **shape** (uniform per season — e.g. S1 = rectangle, S2 = speech
  bubble, S3 = lightning bolt — freely chosen from your earned pool) + **auto-populated rank
  text** ("Masters S1 #12") + **tier-tinted outline** (bronze→bronze, gold→gold, …; **Masters =
  animated multi-color**, per the runtime-tint rule). Optional **sticker background** layer.
- **Earned, not bought:** you **start with zero stickers** (no shape, no text). Each Ranked
  season placement grants **one** sticker (shape + the season's title). Over many seasons the
  board edges accrete a graffiti wall of past flexes.
- **Toggle** to show/hide for players who don't want to flaunt it.
- **Source art owned:** speech bubbles, sign posts, the level-map pack's stars/flags, banner
  shapes — shapes come free; new shapes are minutes of authoring. One new shape per season is a
  non-problem for 15+ seasons, and a new shape ships in every tier instantly (runtime tint).
- **Guardrail:** visual-only, chrome-only; glow/fire on higher tiers stays subtle and in the
  margin, never bleeding into the play area.

**Ranked reward bundle (every placement, same *type*, scaled by tier — never "better," just
recognizable):** a **Title** ("Masters") + a **Frame** (tier border) + a **Rank Sticker**. These
are **prestige: Ranked-exclusive, never on the season track, never buyable.** Season track = what
you've collected; Ranked = who you are.

---

## Source × rarity (rarity = how hard it was to get, never luck — no gacha)

- **Common** — campaign completion, first-time milestones, season-track tiers.
- **Rare** — Trials leaderboard placement, deep season tiers, achievement chains.
- **Prestige** — Ranked tier + seasonal placement (Title + Frame + Rank Sticker). **Never
  buyable, ever. Never on the season track.**
- **Paid** — optional themed DLC packs, one-time. **Disjoint from earnable + prestige.**

---

## IA — two homes, not three tabs

- **Collection** = Locker + Codex merged. One screen, two lenses on the same catalog: loadout
  lens (equip what you own) + collection lens (completion %, locked silhouettes, buy). Stickers
  equip here too.
- **Season** = its own surface, surfaced everywhere (home widget + post-match nudges + the full
  track). XP comes from tasks (`notes/task_system.md`), not from playing. See `design/SEASON.md`.

---

## Codex / sticker-book behavior (the collection lens)

- Owned → full real art + rarity tag, equippable.
- Earnable-but-unowned → **black silhouette** + how-to-earn hint ("Reach Gold III").
- Paid-but-unowned → **dimmed real art** + buy affordance. The codex doubles as the storefront.

---

## Asset manifest

See `notes/asset_catalog.md` for the full slot-mapped, owned/free/$-tagged catalogue (built from
a complete scrape of the store), `notes/gds_catalog.csv` for the raw 1277-pack index, and
`notes/asset_buy_list.md` for the tiered acquisition list (free-on-membership grabs first).

---

## Deferred (structure locked, contents/numbers later)

- **Exact season point values + the score-task definition** — see `design/SEASON.md` /
  `notes/task_system.md` open forks.
- **CC import tasks:** export a catapult PNG body; import alt mobs + alt biomes into
  `src/assets/` as packs are promoted; build the board-sticker render layer (chrome-edge,
  runtime outline tint + Masters animated stroke).
