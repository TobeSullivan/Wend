# JUICE — Wend game-feel & motion

Status: **foundation LOCKED 2026-06-08.** Lens + motion language + break-the-grid grammar are settled and validated against the victory surface. Per-surface specs build on this base.

Visual tokens (palette, radii, bevel, shadow, Fredoka SemiBold + outline) are inherited from `design/VISUAL_SYSTEM.md`. This doc is motion + grammar, not styling. References render the feel: `notes/mockups/juice_motion_reference.html` (the language) and `notes/mockups/victory_screen_mock.html` (it applied).

---

## The lens

Juice for Wend is **not audio.** TD players mute — shooting chatter and an EDM bed are exactly what gets turned off first. So our game-feel comes through **transitions, animations, impact events, staged set-pieces** (victory, rank climb, high-score / ghost climb), and **UI that overlaps the play surface** instead of sitting in boxes beside it.

The reference is Atlus (Persona / Metaphor), but the **principle, not the skin.** We steal the behavior — nothing teleports, UI moves with intent, UI is allowed to break its box and overlap the field — and wear Wend's own look. Fredoka is round and friendly, so the register is closer to a warm comic-poster attitude than Persona's gothic edge. **Not red and black.**

The guardrail that protects the game from the style: **the playfield stays legible and calm.** Angle, overlap, and motion live in the frame and in the moments between rounds. Nothing churns the board while it's being read to place a tower.

Optional and **undecided** (Tobe's call): a single restrained sting on impact-events only — victory, rank-up, a high-score beat. Consistent with the lens (those are the staged moments), but flagged, not built. Easy to omit entirely.

---

## Motion foundation

### Timing scale (ms)
`XS 90` taps / micro-feedback · `S 160` single element · `M 260` panels, transitions (the default) · `L 440` staged set-pieces only · `screen 320` full screen-to-screen. Exits run on the short end. **L is earned** — spent on a hero moment, never on routine UI.

### The three verbs
Nothing teleports. Everything arrives, settles, or leaves.
- **Arrive** (enter + settle): `cubic-bezier(.34, 1.32, .5, 1)` — fast in, ~10–12% overshoot, settle. The signature curve.
- **Settle** (reposition, no overshoot): `cubic-bezier(.22, 1, .36, 1)`.
- **Leave** (exit, always quicker than the arrival): `cubic-bezier(.4, 0, 1, 1)`.

### Emphasis pop
A value that just changed gets one quick scale pop `1.0 → 1.14 → 1.0` over `S`. That is the entire vocabulary for "a number moved" (gold spent, score climbed, LP gained).

### Stagger
Sibling sets cascade, never arrive all at once: `60ms` per item baseline; set-pieces may widen to `~130ms` for drama. Stars fill low → high; ladder rungs climb bottom → top. Cap the visible stagger so a long list doesn't crawl.

### Spatial grammar
Elements enter from the edge they belong to — rail from the right, toast from the top, a result rises from the play. **The board never moves while it's being read.**

### Reduced-motion
A toggle drops overshoot → plain ease and shortens durations. Cheap, do it.

### Arm before reveal
Set an element's (or a whole screen's) pre-entrance state **before** it becomes visible, then animate in. Never reveal a screen at its final state and then re-trigger the entrance — that flashes the end frame first and reads as a bug. This is a sequencing rule, not a design change (it was the one real glitch caught in the mocks).

### Godot map for CC
`arrive → TRANS_BACK, EASE_OUT` (tune the overshoot constant *down* to ~10–12%; Godot's default back is stronger) · `settle → TRANS_QUINT, EASE_OUT` · `leave → TRANS_CUBIC, EASE_IN` · `pop → quick scale tween on TRANS_BACK, EASE_OUT`. **Promote the durations + curves to one shared helper** so no surface re-invents them — that single source is what makes it read as one authored hand.

---

## Break-the-grid grammar

- A styled box is **one tidy unit**: text contained, sitting on the box's own angle. Text never escapes its container.
- **Overlap happens between elements** — box over playfield, box over a neighboring panel — *not* text over its own box. Text breaking out reads as a bug.
- **Depth is the box's own bevel** (the +2/+3 bottom border) **plus its shadow.** Never a stacked duplicate shape behind it — that move is rejected, it reads awkward.
- **Tilt is subtle** — ~3–4° off-axis, on frames, heroes, and set-pieces only.
- **Precision / interactive targets stay axis-aligned**: buttons, the build cursor, the board itself, and any panel of numbers you read or act on (the tower inspector's stat grid). Style lives on the frame around them, not on the thing you're aiming at.
- **No invented assets.** The attitude — angled boxes overlapping the surface, contained outlined Fredoka, bold color blocks — comes from transforms + type + palette only. The reference art's pointing hand, dice, and character cut-ins are bespoke assets we do not have.

---

## Surface backlog

All distinct surfaces are mocked and validated this session. Mocks live in `notes/mockups/`.

- ✅ **Motion foundation** — locked (this doc). Ref: `juice_motion_reference.html`.
- ✅ **Victory / result screen** — staged choreography + break-the-grid hero. Ref: `victory_screen_mock.html`. Folds in **polish #7**: star tiles get a full clean outline (the corner-only outline that read as a bug is gone). Leave-only flow.
- ✅ **In-match HUD** — rail arrival (stagger from the right), the contextual tower overlay overlapping the live board (deliberately **low-overlap** — only the header tab angles; the stat grid stays square because it is read and aimed at), and the build→run phase flip. Ref: `inmatch_hud_mock.html`. The in-rail overlay alternative stays unused unless a real playtest shows the corner panel occludes needed cells.
- ✅ **Meta menu** (home / Thread-Weave-Tangle select) — the attitude surface, where overlap + angle flex (tilted, offset hero buttons; angled name tabs). Includes the home→select **screen transition** (the connective-tissue layer). Ref: `meta_menu_mock.html`.
- ✅ **Staged climbs** — Ranked Surface 2 (placement, LP bar fill on the settle curve, tier-up promotion as a staged L-duration set-piece) and the in-match ghost-ladder (passed rung leaves the top, next ghost arrives from the bottom; never asserts a live mid-match rank). Ref: `staged_climbs_mock.html`.
- ✅ **Round-end overlay** — one transient over-board system, two payloads: Trials gold/score deltas pop, Ranked pairwise lives swing. Ref: `round_end_overlay_mock.html`.

### In-match beats
- **Tower color deepen on upgrade:** the pale→vivid→near-black ramp is **existing, locked game identity, unchanged.** The juice contribution is *only* the emphasis-pop on the tower at the instant it deepens, so an existing-but-silent state change lands as a felt beat. (Shown in `inmatch_hud_mock.html`; the mock's indigo colors are an illustrative placeholder, not a proposed recolor.)
- **Wave clear** (toast drops from the top), **build→run phase flip**, **supply-out cursor stop** (= polish #8: auto-stop the placement ghost when it can't be afforded). All reuse the arrive/leave/pop vocabulary; no separate mock.

### Inherits the grammar (no separate spec needed)
Pause overlay, Settings overlay, Campaign select, and generic menu transitions inherit the established grammar: panels arrive/leave on the foundation curves, headers may tab-angle, content that is read or acted on stays square. Build them against this doc + the meta-menu mock.

## Open dials (numbers, not shape)
Hero tilt −3.5° and the 130ms set-piece stagger are provisional — tune in playtest. The impact-event audio sting is flagged and undecided.

## Note for CC
Every spec here is **motion + layout + type + color — no new art.** When implementing, match the mocks' feel, tune the Godot overshoot constant to land ~10–12%, and **arm entrance state before revealing a screen** (see Arm before reveal).
