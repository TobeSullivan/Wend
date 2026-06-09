# PVP lobby — design note

Captured 2026-06-05. Screen-by-screen layout added 2026-06-09. Two distinct paths.
The current `lobby.gd` CONNECT/ROOM (name + Host/Join-by-IP) is **transitional dev
scaffolding** for testing the dedicated server — it is NOT the shipped PVP entry and
must not reach players as-is.

## Ranked (queue, no codes)
Locked design: "tap PVP → queue immediately, est. wait, nothing to configure."

`Idle → Queued(searching: est. wait + cancel) → LobbyFormed(countdown, see opponents'
names/ranks/season boards) → InMatch → PostMatch(LP delta + placement + ladder → requeue/home)`

- **No codes, no host/join.** Server forms the lobby.
- Under low population: **shrink the target lobby** (8→6→4→2) and **widen rank bands**,
  never bot-fill. (No bots in ranked, ever.)

## Inviting friends → Steam overlay (no room codes) — LOCKED 2026-06-09
**Friends are invited through Steam, not through a custom code system.** An "Invite"
button in the lobby pops the **Steam overlay** friend-picker; the user can also invite
via shift+tab → Steam overlay. There is a real in-game lobby interface; Invite is one
control inside it that hands off to Steam.

- **The 4-digit room-code idea is DEAD** (it was the old "friends join my game from their
  houses" mechanism — Steam invites replace it). Drop codes from the design.
- Because invites ride Steam, **all multiplayer-with-friends is Steam-gated** — same gate
  as everything else. Co-op Trials (party > 1) is not testable until Steam clears. Not a
  beta hole; consistent with the rest.
- The button label is just **"Invite"** — "via Steam" is redundant (the overlay opening is
  the implied mechanic). Empty party slots render as clearly-tappable add-a-player buttons,
  not dead space.

## Bots (unranked practice only)
Bots remain allowed in **offline / unranked practice** (nothing touches the ladder). They
are NOT a lobby-join mechanism and never enter Ranked.

## Gating
Real matchmaking is blocked on **Option B (concurrent matches)** — now BUILT (3a–3d, the
room-router match server is live). The queue UX is real and the spine is wired end-to-end;
the remaining gap is the human 2-client cross-network run, which is **distribution-gated
(Steam)**.

---

## Screen-by-screen layout — ADDED 2026-06-09 (the open item below is now CLOSED)
Mock: `notes/mockups/lobby_mock.html` (four states, fictional names, WEND identity).
Applies the locked JUICE grammar (`design/JUICE.md`) — beveled boxes, break-the-grid tag,
arrive-stagger on rows, board-stays-calm — and the cosmetics flair model
(`design/COSMETICS.md`).

**Four states:**

1. **Ranked — searching.** RANKED tag + "Finding a match", a searching spinner, est. wait
   (~30s), a "tier band: same → widening to any" feedback bar (the escalation schedule made
   visible), your own identity card, and a free **Cancel search**. Pre-lobby, only you on screen.

2. **Ranked — forming lobby.** The meaty one. A prominent **X / 8** counter with square pips
   (filled = seated) and "auto-launches at 8". A list of seated players, each a **row** with:
   avatar + **compact frame ring** (cosmetic) + name + **title** (cosmetic) + tier pill + LP.
   Your row is green-bordered. Empty seats show "Finding player…" placeholders. A **vote box**
   ("Launch now" + "N / M voted" + "Everyone present must agree") is present whenever the count
   is at/above the floor. A free **Leave**, and a wide-search hint. **Mixed tiers in one lobby
   are intentional** (speed-beats-quality, safe because LP is MMR-anchored).

3. **Player card (tap target).** Tapping any row opens a floating card over a dimmed lobby:
   a **banner** strip (cosmetic), avatar with **frame** overlapping it, name, **title**, a
   tier / LP / global-rank stat trio, and a season chip. This is the "full flair on tap" half;
   rows carry the "compact flair" half. (Flair render-home LOCKED 2026-06-09: **both** — small
   on the row, full card on tap.)

4. **Trials — co-op party (host view).** The lighter cousin. A window/scale context strip
   (e.g. "Weekly · Tangle · Map 3 of 5") with a **board-size tag** (Solo/Duo/Trio/Quad) showing
   which leaderboard the combined score posts to. Party slots (1–4): your HOST row, seated
   friends, and **"Invite"** buttons (→ Steam overlay) for empty seats. **No vote, no
   matchmaker** — the host hits **Start run** unilaterally. Caption: "Scores combine to the Duo
   board". The non-host view is identical with "Start run" → "Waiting for host".

**GO / launch beat** reuses the existing `scene_manager.gd` cross-scene wipe — not a new
screen, just "lock, then go".

**Ranked vs Trials, at a glance:** Ranked = solo-queue, fills X/8 with strangers, gates on the
unanimous-of-present vote (or auto-at-8). Trials = invited party, host launches when they want,
no vote, board-size = the leaderboard bucket.

---

## Open
- ~~Full screen-by-screen layout~~ — **DONE 2026-06-09** (`lobby_mock.html` + the section above).
- Population strategy for liquid ranked queues at small scale (power-hour windows? async/
  ghost competition? seed with committed core?). This is the existential PVP risk — the
  predecessor died on empty queues. **Still not solved** — out of scope for the beta (closed,
  invite-driven), but the launch GTM/retention problem.
- Lobby motion dials (row-arrival stagger, vote-tally pop) are playtest items, inheriting the
  JUICE foundation.
