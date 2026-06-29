# Design Revisions — 2026-06-22

> CC: apply these to `notes/decisions.md` and `notes/test_case_library.md`, then
> implement the merge/mob changes. This session reversed two core pillars — read
> the pillar change first, because downstream files currently enforce the OLD model.

---

## 1. PILLAR CHANGE (the big one)

**STRIKE these locked pillars:**
- ~~Mobs respawn in place~~
- ~~Score-attack replaces survival (no fail state)~~

**REPLACE with:**
- **Mobs die and stay dead.** Permanent kills, like a conventional TD. This is a
  deliberate decision (made after external playtesting/conversations, not in haste) to
  widen the audience beyond the original custom-map players and avoid the "why aren't the
  mobs dying?!" bounce.
- **Escalation via difficulty scaling.** Difficulty ramps until it outpaces the player.
  A normal maze caps out around **stage 30**; a great maze pushes further. (Scaling curve
  TBD — not this session.)
- **Fail state = lives.** Leaks cost lives; running out ends the run.
- **Leaderboard = round reached + score.**

**UNCHANGED pillars (still locked):**
- Maze geometry + bonus-zone placement + upgrades remain THE depth axes.
- One tower type (with the merge tier ladder).
- Warm olive/gold/terracotta identity, Fredoka, break-the-grid framing.

**SOFTENED:** "one mob type" — now one standard mob type **plus a periodic boss** (see §2).

---

## 2. NEW LOCKED DECISIONS (add to decisions.md)

- **Boss rounds:** every 10 rounds, a boss appears **among** the mob wave (not a solo
  encounter). Leaking the boss costs a large chunk of lives.
- **Trials lives:** ~10 lives (exact integer TBD).
- **PvP:** 100-life see-saw, last-player-standing wins, **score is the tiebreaker.**
  The see-saw transfers on **leaks, not kills.**
- **Merge mechanic:**
  - Same-tier only; two of tier N → one tier N+1.
  - **Pure merge** path to tier. Upgrades do NOT raise tier. Max **T10** (2ⁿ cost; high
    tiers are aspirational, reached only with a strong tower economy).
  - Merging **empties the source tile** → leaves a hole in the maze. Build-time pressure.
- **Multishot:** the dominant damage lever. Unlocks at tiers **3 / 6 / 10 → ×2 / ×3 / ×4**
  (cap 4). ×3/×4 are aspirational given the 2ⁿ cost.
- **Tower appearance morphs per tier.** Barrel count = multishot count (functional read
  lives in structure, not body color → body stays a skin slot). Tier badge shows exact tier.
- **Controller / Steam Deck input:** tap-to-arm (cursor → action arms → direction merges →
  auto-disarm). Mouse: drag onto adjacent same-tier. Steam Deck is the near-term controller
  target (Tobe has a Deck to test on).

---

## 3. TEST CASE LIBRARY REVISIONS (`test_case_library.md`)

**Rewrite these 🔒 stop-the-line cases — they encode the reversed pillars:**
- 🔒 "mobs respawn in place" → **"mobs die permanently; difficulty scales until it
  overwhelms; normal maze caps ~stage 30"**
- 🔒 "score-attack win condition / no fail state" → **"lives-based fail state; leaderboard
  = round reached + score"**

**Adjust:**
- 🔒 "one mob type" → "one standard mob type + periodic boss (every 10 rounds, among the wave)"

**Add new 🔒 cases:**
- Merge is same-tier only; pure-merge to tier; max T10; multishot cap 4.
- Merging empties the source tile (hole-in-maze risk must be visible).
- PvP see-saw transfers on leaks, not kills; score tiebreak.
- Boss leak applies the heavy life penalty.

**Unaffected 🔒 cases (leave as-is):** free season shows no pricing, opponent skins don't
leak, room codes dead, upgrade legibility survives skins, Stone/Bronze/Silver/Gold/Masters
rename.

---

## 4. MERGE / JUICE SPEC (for CC implementation)

Reference build: **`wend_merge_reference.html`** (open in a browser — interactive, shows the
exact feel + tier morph + stat scaling).

- **Feel:** cartoon and fun, NOT impactful. **No screen shake.** Merge result wobbles with a
  gummy jelly squash-and-stretch that decays and settles. Impact = soft pastel poof, not a
  hard white flash.
- **Sequence:** anticipation (bouncy squash + slight pull-back) → quick travel into target →
  poof + jelly wobble on the new tower → source tile flashes a "gap!" hole cue.
- **Input states:** cursor (selected) vs armed (lifted) are distinct visual states so the
  player always knows whether a direction will MOVE or MERGE. Invalid merge = reject nudge.
- **Appearance:** body color walks a 10-stop ramp; barrels = shot count (1 → ×2 at T3 →
  ×3 at T6 → ×4 at T10); tier badge shows the number; T10 gets a gold accent ring.
- **Stats:** placeholder in the reference (`dmg×1.20^n`, `rate×1.05^n`, `range+6/tier`,
  `dps = dmg × shots × rate`). Real scaling TBD — do not hard-code these as final.

---

## 5. CC IMPLEMENTATION HANDOFF (also mirror into open_items.md)

- Mob model: mobs die permanently; build the difficulty-scaling ramp (target: normal maze
  ~stage 30 cap). Boss every 10 rounds among the wave, heavy leak penalty.
- Lives: Trials ~10; PvP 100-life see-saw on leaks; score tiebreak.
- Merge mechanic: tap-to-arm + drag, same-tier, 2ⁿ to T10, source-empties-leaves-hole.
- Merge juice per `wend_merge_reference.html` (jelly, poof, no shake).
- Tower visual morph per tier (barrels = shots, color ramp, tier badge).
- Stat hooks: multishot 3/6/10 cap 4; other stats stubbed, scaling deferred.
- Apply the decisions.md + test_case_library.md edits in §1–§3 (or flag for the next
  repo-cloned design session to do).
