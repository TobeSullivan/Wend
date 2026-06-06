# Matchmaking & orchestration

**Read `claude-rules.md` → `RULES.md` → `STATE.md` first.** Designed 2026-06-06.

This doc owns the **orchestration spine**: the lifecycle from "player presses queue" to "match instance torn down," plus the failure handling around it. It does **not** re-specify things the adjacent locked docs own — it sequences them and hands off:

- In-match round/transfer/elimination mechanics → `design/DESIGN_MODES.md`
- Authoritative scoring / re-sim contract → `notes/resim_contract.md`
- LP / MMR / tiers / seasons → `notes/pvp_ladder.md`
- Leaderboard board-id schema & writes → `notes/leaderboard_schema.md`
- Transport, backend, costs, the no-bots-in-ranked policy → `notes/multiplayer_architecture.md`
- Server/host decision → `notes/server_decision.md`

---

## Coordinator placement (recommendation; CC validates)

The authoritative live coordinator lives as a **Nakama authoritative match handler**, not a per-match headless Godot process. The round-barrier model means the coordinator only relays kill counts at round boundaries and runs the pairwise-transfer math — it needs no renderer and no sim, so a Godot process per match is wasted weight. Many light matches per box; native to the backend already chosen (`multiplayer_architecture.md`).

**Re-sim validation** is the only thing that needs a faithful Godot sim, and it's async / post-round — so it runs as a **separate headless-Godot worker pool**, invoked out-of-band by the server. This is exactly the Option-B (light live relay) + re-sim (heavy authoritative validation) split the existing docs describe: live coordination is cheap and in Nakama; truth is computed by Godot workers, off the hot path.

If CC finds the match-handler runtime impractical, the model is unchanged — only where the coordinator code physically runs.

---

## Ranked lifecycle (the spine)

1. **IDLE** → player presses Queue. Client submits a matchmaker ticket: `{ mode: ranked, season, lp, band, platform }`.
2. **QUEUED** → an **escalation schedule** widens tolerance and lowers the count floor over time. The terminal state is "match anyone in queue, down to the floor." Illustrative dials (tune from queue-time telemetry — guesses, not locked):
   - t0: prefer same tier, want 8
   - ~15s: band ±2 tiers, accept 6
   - ~30s: band = any rank, accept down to the floor
   - hold at want-floor / any-rank until it fills
   **Speed beats quality** (user call): a Master dropped into a Silver lobby is fine and explicitly preferred over no match. This is safe for the ladder *because LP is MMR-anchored* (`pvp_ladder.md`) — beating a higher-MMR player pays more, losing to one costs little; the fed Silver doesn't bleed, the Master doesn't farm. **If LP ever flattens to placement-only, revisit this — fast-and-wide matching depends on the MMR anchor.**
3. **FORMING LOBBY** → the matchmaker routes players into a **filling lobby**, not a silent pop-at-N. The lobby shows **X/8** and fills as players are fed in.
   - **At 8** → auto-lock, auto-launch. No vote.
   - **At 4–7** → a "launch now" vote is available. **Unanimous of everyone present**; **not voting is a no**; abstain blocks. (If all 7 present don't vote yes, it does not launch.) No timeout, no backstop, no forced launch — impatient players vote, lobbies move; if one sits, it sits.
   - **Below 4** → cannot launch; keep filling.
   - Pre-launch, leaving the lobby is free and unpenalized (drops the count).
4. **INSTANCE_REQUESTED** → on launch (vote or auto-at-8), Nakama creates the authoritative match, returns a `match_id`.
5. **JOINING** → clients join `match_id` within a join window. **Instant-join, no ready-check** (user call): every queuer is treated as committed. The coordinator runs variable board count, so if only 6 of 8 make the window it starts as a 6-board match; below the floor (4) it cancels and priority-requeues the joiners.
6. **RUNNING** → build phase → run phase → round barrier → pairwise transfer → repeat (`DESIGN_MODES.md`). The coordinator collects each player's seed + ordered input log per round — the re-sim payload (`resim_contract.md`).
7. **RESOLVING** → elimination resolves to a winner. Coordinator submits results + input logs.
8. **VALIDATING** → a headless-Godot re-sim worker replays each log → true kill counts → confirms placement. **Re-sim truth is authoritative**; client-reported values are discarded on mismatch and the discrepancy is flagged to the anti-cheat ledger (policy owned by `resim_contract.md`; orchestration only provides the hook).
9. **SETTLED** → LP applied (`pvp_ladder.md`), ladder updated (`leaderboard_schema.md`), result screen shows placement + LP + global-rank delta (`leaderboard_ui_spec.md`, `ghost_ladder.md`).
10. **TEARDOWN** → instance destroyed, resources freed.

### Match count floor

Floor is **4** for a Ranked launch. Below 4 the mode collapses from "hybrid elimination" to a duel; keep waiting / widening instead of dropping to 2–3. (Revisit if thin-pop telemetry says 4 is too high to ever fill.)

### LP regardless of lobby size

LP is computed identically for an 8-, 6-, or 4-player match — the MMR-anchored model already prices opponent strength, so a strong 4-player match pays correctly. Not scaling LP by lobby size is a deliberate simplicity call.

---

## Failure handling

- **Lobby stalls** → not engineered around. People are impatient; someone votes. If a lobby genuinely sits, it sits. No timeout/backstop by design (user call — don't over-engineer human behavior that self-corrects).
- **Partial join** → start short (variable board count); cancel + priority-requeue only below the floor.
- **Post-launch drop** → a **forfeit**. The match proceeds; the dropped slot runs as an empty-input board from the point of leaving and self-eliminates under the locked forfeit rules (`resim_contract.md`: empty-input continuation, "disconnected" badge, eliminated if it dies before return, server-observed timeline, zero advantage to quitting). "Going with or without you" is literal.
- **Reconnect** → the match handler holds the slot open for reconnect for the full match duration; client rejoins the same `match_id`.
- **Instance spawn failure** → joiners back to queue with priority + a brief apology toast.
- **Coordinator crash mid-match** → match **voids, no LP change either direction**, players requeue. Rarity + symmetric no-penalty makes this acceptable without building match reconstruction. (Per-round logs *could* reconstruct it later since the model is re-simmable; not worth building for beta.)
- **Re-sim mismatch** → re-sim value wins, client value discarded, discrepancy flagged. Closes score-injection, not botting (stated boundary in `resim_contract.md`).

---

## Trials through the same spine (lighter)

Trials reuses the spine **minus elimination, minus matchmaking**. It is invite-only co-op, never random queue (`DESIGN_MODES.md`).

- **Solo:** no matchmaker, no forming lobby. Local authoritative run → submit seed + input log → re-sim → leaderboard bucket.
- **Group (1–4):** the **host** invites friends and **launches unilaterally when they want** — no fill-up matchmaker, no unanimous vote, no ready-up gate (those are Ranked-only). The group lands at INSTANCE_REQUESTED → JOINING → RUNNING with **elimination and life-transfers switched off** — players share a map/window but run independent boards. Team score (sum of damage) posts to the group-size board (Duo/Trio/Quad); solo posts Solo.

Designing the Ranked spine first gave the Trials group a defined socket to land in: same instance/join/run/validate path, different (lighter) entry and no zero-sum layer.

---

## What's a dial vs what's locked

**Locked:** the lobby model (instant-join, fill X/8, unanimous-or-auto-at-8, abstain = no, no timeout, post-launch drop = forfeit); floor at 4; LP independent of lobby size; coordinator-crash voids with no LP; re-sim authoritative. Trials = invite-only, host launches, no elimination.

**Dials (need queue telemetry / playtest):** the escalation schedule timings and band widths; the join-window length; whether floor-4 holds on a thin population.

**Deferred / additive:** a ready-check (ships off; flip on only if AFK-poisoning shows up in testing — it's additive, costs nothing to defer); match reconstruction after coordinator crash.
