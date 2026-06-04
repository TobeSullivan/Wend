# In-Match Fixes — Claude Code Tasks

Last updated: 2026-06-04
Repo path: `design/INMATCH_FIXES.md`

Two real in-match fixes came out of the 2026-06-04 design pass. Grass is fine as-is
(optional: swap to the seasonal grass tiles + scatter `rubble_pieces` as non-blocking
decals for liveliness). The board letterbox is RESOLVED (grass is full-bleed now).
Each task below is scoped tight with an acceptance test and a hard fence — do not
exceed the fence; if you can't meet acceptance within it, STOP and report.

---

## 1. Obstacles → real sized environmental props

Today obstacles are placeholder single-tile rocks. The art pack has a full urban-decay
set that should replace them, and props should be allowed to be larger than 1×1.

**Schema reopen (required).** The locked `MapResource` stores obstacles as bare cells
(`obstacle_cells: Array[Vector2i]`), which is why multi-tile props were dropped. Add an
obstacle definition that carries:
- `prop_id` (which art asset)
- `footprint: Vector2i` (cells it occupies)
- the cells it actually **blocks** (= footprint)

**Visual overhang allowed.** The drawn sprite may spill *beyond* its blocked cells (a
building ruin overhangs the 2×2 it blocks) so the world looks real without eating extra
build space. Block = footprint; draw = sprite, base-anchored, can be bigger.

**Props (curate per map; `art/environment_art/`):** `props/car_reck`, `props/truck_on_side`,
`building_ruins/building_ruin_01..15`, `props/dead_tree_01/02`, `props/oil_drum_*`,
`props/street_lamp_*`, `props/hydrant`, `props/tire_*`, `props/wheelie_bin`, etc. Favor the
cleaner wrecks (cars, drums, trees, lamps); use the big building ruins sparingly so the
board doesn't get busy.

**Generator + pathfinder:** the generator places sized obstacles; the pathfinder validates
a clear entry→checkpoints→exit around the blocked footprints (same validation as today,
just multi-cell).

**Acceptance:** maps render varied real props (not rocks); multi-tile props block their
full footprint; sprites may overhang; a valid path still exists; no path/placement
regressions in campaign/PVE/PVP.

**Fence:** this is a deliberate schema reopen — it WILL touch `map_resource.gd`,
`map_generator.gd`, `map_loader.gd`/obstacle rendering, and the campaign `.tres` files.
That's expected. Do not refactor unrelated systems.

---

## 2. Movement-direction chevrons (verbatim spec)

The current chevrons are bad: too dense, too faint, they fade in/out, and they look like a
typed `>` rather than a drawn shape. The mechanism (scroll shader on the road) is correct —
this is appearance + motion only.

> **Task: fix the movement-direction chevrons on the road. Narrow scope — do NOT refactor.**
>
> The chevron mechanism already exists (scroll shader on the road in `road_renderer.gd`).
> You are only adjusting its appearance and motion. Match the reference image.
>
> Change ONLY these:
> 1. **Shape:** a solid filled chevron drawn by the shader/texture — NOT a font `>`
>    character. Cream fill `#f4e7b6` with a dark edge `#4a3a16`.
> 2. **Opacity:** fully opaque, constant. Remove all alpha fade — no fade-in/out, no
>    pulsing. Only the scroll offset animates. (The fading is the current bug.)
> 3. **Spacing:** ~1.5 tiles apart along the path (currently far too dense).
> 4. **Size:** chevron height ≈ 0.4 tile.
> 5. **Speed:** scroll toward the exit slowly, ~1 tile/sec.
>
> **Hard fence — do not touch:** pathfinding, the `Line2D` road geometry,
> `build_controller`, the build/hover system, or anything outside the chevron
> material/texture + its 3–4 uniforms (spacing, speed, color, size). No per-frame node
> spawning.
>
> **Acceptance (verify before saying it's done):** chevrons evenly spaced ~1.5 tiles, each
> a solid opaque shape with zero flicker/fade, readable on the tan road, flowing toward
> exit at a calm pace. Build-mode path still updates. No memory growth over a 2-min run.
> **If you cannot achieve this by editing only the chevron material/texture and its
> uniforms, STOP and report — do not refactor the road or path system.**
