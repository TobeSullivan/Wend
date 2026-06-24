# State — Wend
Last updated: 2026-06-23

## Current focus
Three threads: (1) Steam Playtest build is **in review** (submitted Jun 22, 3–5 biz days);
(2) the 2026-06-22 pivot (mobs die permanently + merge ladder) is **implemented by CC** and the
core docs are reconciled — remaining work is balance tuning (playtest-gated) + stale UI/tutorial
follow-ups; (3) the tower **tier aura** is now **implemented by CC** per `design/TOWER_AURA.md` —
remaining is the playtest eyeball + the design-session `test_case_library.md` case.

## Last session
- **Tower tier aura — implemented (CC).** New `tier_aura.gd` (`TierAura`): a radial
  `GradientTexture2D` ground glow drawn behind the body, offset to the feet, tier-driven
  (diameter/opacity/period) with a breathing pulse on a looping Tween (visual frame time, respects
  `Motion.reduced`). Per-board warm/cool ramp resolved on the `is_local` split (opponent→default
  cool), threaded `map_loader` → `build_controller` → `tower` alongside the skin/tint path.
  Retired the body-color RAMP tint (body = pure skin slot); merge poof now recolors off the aura
  ramp. Reconciled `design/COSMETICS.md`, `design/DESIGN.md`, `notes/wend_merge_reference.html`.
- **Verified:** clean headless import (no parse/shadow warnings); `sim_harness` round-trip
  bit-identical **with merge actions** + tampered logs rejected (determinism untouched — aura is
  render-only); `match_shot` runs clean (towers + aura nodes instantiate, no runtime errors).

## Next step
- **Playtest the aura at real maze density** — eyeball spec §3 values (muddy glows → pull
  opacity/diameter down); decide whether the optional T3/T6/T10 milestone "notches" are needed.
- In parallel, **playtest-tune the pivot:** per-tier stat curves + difficulty ramp (~stage-30 cap),
  lives integers, rewrite stale tutorial/end-panel copy.
- Apply the `test_case_library.md` §3 edits **plus** the new aura 🔒 case in the repo-cloned design
  session that owns that file (not in CC's checkout).

## Recently touched
- src/scripts/tier_aura.gd (new — this session)
- src/scripts/{tower,build_controller,map_loader,cosmetics_catalog}.gd (aura wiring — this session)
- design/COSMETICS.md, design/DESIGN.md, notes/wend_merge_reference.html (reconciled — this session)
- notes/open_items.md (aura → implemented), STATE.md (this file)

## Open questions / blocked on
- **Steam:** review pending (can pass before the **21-day app-credit gate**, ~mid-July, that blocks
  Playtest going Playable). When verification clears: create App ID → confidential Playtest app.
- Stat scaling curve + lives integers deliberately deferred to playtest.
- `design/COSMETICS.md` aura line still says "ring" — one-line reconcile owed (tracked in open_items).
- `test_case_library.md` not in CC's checkout — its §3 rewrite + the new aura case are owed by the
  repo-cloned design session.
- Real capsule/key art still pending for the public Coming Soon page.
- Possible second game for Feb 2027 Next Fest — undecided.
