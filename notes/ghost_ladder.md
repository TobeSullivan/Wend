# In-match ghost ladder — target display spec

**Locked 2026-06-06 (session 3).** Lands at `notes/ghost_ladder.md`.
Defines the in-match "next score to beat" element for Trials. Mockup: states A in
`notes/mockups/leaderboard_ui_pass2.html`.

---

## What it is

A single in-match element that **always shows the next score to beat** and a sense of
climbing — without ever asserting a live leaderboard rank. It **merges the named tier
thresholds and the leaderboard into one ascending ladder of score-targets.** Below gold you
pass the named tiers; above gold you pass the scores real players set. Gold isn't the end —
it's where the named tiers run out and the human ladder begins.

It replaces the old fixed Bronze/Silver/Gold-only target display and sits where that target
sits in the v3 in-match HUD.

---

## The ghost model (why it never lies about rank)

You race a **snapshot**, like a racing game's ghost car — not the live, updating board.

- The `(map, window, group-size)` board is **snapshotted once at match start.** Because
  everyone on that board shares the same snapshot, it's **one cached read fanned out** to
  all players that window — not a per-player query, not a live stream. Cheap, and
  population-independent.
- The targets derived from it are **fixed for the whole run** — stable rungs. (Live-sync
  would let a target move *away* from you mid-run when someone improves; stable rungs feel
  better and motivate more.)
- In-match copy shows **scores to beat**, never "you are #N." A persistent
  **"standings as of match start"** caption is the contract that makes this honest.
- The **live rank reveal happens only on the result screen**, where your re-sim'd score
  posts to the real board. Because in-match you chased scores (not a rank), the result is a
  payoff, not a contradiction.

---

## Target-line states (in order)

The line always points at something until there's genuinely nothing left:

1. **Below gold — named tier.** Next target = the next of Bronze / Silver / Gold scores
   (baked into the map). Badge: tier name.
2. **Above gold — ghost score.** Next target = the next snapshot score above your current,
   shown with the player's name. Badge: GHOST.
3. **No ghosts left (empty / brand-new board, or you've passed them all but not your own
   best).** Next target = **your own previous best** on that map. Badge: YOUR BEST. This is
   the population-independence fallback — a dead board still gives you something to chase.
4. **Cleared the snapshot — TOP.** No targets remain. Show **your score only** and a short
   tag (display label **"TOP"**) + "live rank at run's end." No rank asserted. The ladder
   simply ending is itself the reward beat; the real #1 reveal waits for the result screen.

Optional secondary: a **"passed N this run"** counter (running comparison of your live score
against the snapshot target list). Small new data need — drop if it reads as clutter.

**HARD RULE:** in-match text must never assert a live rank ("#112", "you're 1st"). Only
"NEXT: <score>" / "TOP" / your own score. Live rank lives on the result screen alone.

---

## Result-screen reveal (the only live number)

- **Trials:** your true live rank posts here ("#14 today", or "#1 — new daily best" if you
  topped it for real). Surface 1 in the UI spec.
- **Ranked:** placement + LP delta + **global rank delta** (#41 → #34). Surface 2.

---

## Also locked: remove the Trials "go home?" prompt

The campaign flow asks "leave / go home?" after clearing the gold target. That's a
campaign-ism. **A Trials run goes until its rounds are spent — never interrupt a climb.**
Remove the prompt for Trials; campaign keeps it.

---

## CC handoff

1. Snapshot the board once at match start (cached per `(map,window,group-size)`); build the
   merged sorted target list = named tiers ++ snapshot scores above gold.
2. Each tick, compare live score to the target list → drive the four states; advance the
   target as rungs are cleared.
3. Fallback to own-best when no ghosts; "TOP" when snapshot cleared.
4. Persistent "standings as of match start" caption; never render a live rank in-match.
5. Remove the leave/go-home prompt in Trials only.
6. (Optional) passed-this-run counter.
EOF
echo done