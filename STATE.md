# State — Wend
Last updated: 2026-06-23

## Current focus
Three threads: (1) Steam Playtest build is **in review** (submitted Jun 22, 3–5 biz days);
(2) the 2026-06-22 pivot (mobs die permanently + merge ladder) is **implemented by CC** and the
core docs are reconciled — remaining work is balance tuning (playtest-gated) + stale UI/tutorial
follow-ups; (3) **NEW this session:** the tower **tier aura** is specced and handed to CC for
implementation (`design/TOWER_AURA.md`).

## Last session
- **Tower tier aura — design locked, CC handoff produced.** Previewed the aura on the real repo
  assets (arrow-box + crystal skins over the Suburbia/Summer/Forest tiles). Calls made: **ground
  glow** beats the outline ring (and "both"); **color walks a per-board ramp** (warm on terracotta
  Suburbia, cool on the greens) since no single ramp reads on every board; tower body stays a pure
  skin slot. This **supersedes** the merge-reference "body color walks a 10-stop ramp" tell.
- Wrote `design/TOWER_AURA.md` (canonical spec), updated the `decisions.md` Cosmetics lock
  (ring → ground glow + per-board ramp), and added the CC implementation item to `open_items.md`.

## Next step
- **CC: implement the tier aura** per `design/TOWER_AURA.md` (TierAura node behind the body,
  tier-driven, per-board ramp via the `is_local` resolve path; render-only, off the sim tick).
- In parallel, **playtest-tune the pivot:** per-tier stat curves + difficulty ramp (~stage-30 cap),
  lives integers, rewrite stale tutorial/end-panel copy.
- Apply the `test_case_library.md` §3 edits **plus** the new aura 🔒 case in the repo-cloned design
  session that owns that file (not in CC's checkout).

## Recently touched
- design/TOWER_AURA.md (new — this session)
- notes/decisions.md (aura lock updated — this session)
- notes/open_items.md (aura CC item added — this session)
- STATE.md (this file)

## Open questions / blocked on
- **Steam:** review pending (can pass before the **21-day app-credit gate**, ~mid-July, that blocks
  Playtest going Playable). When verification clears: create App ID → confidential Playtest app.
- Stat scaling curve + lives integers deliberately deferred to playtest.
- `design/COSMETICS.md` aura line still says "ring" — one-line reconcile owed (tracked in open_items).
- `test_case_library.md` not in CC's checkout — its §3 rewrite + the new aura case are owed by the
  repo-cloned design session.
- Real capsule/key art still pending for the public Coming Soon page.
- Possible second game for Feb 2027 Next Fest — undecided.
