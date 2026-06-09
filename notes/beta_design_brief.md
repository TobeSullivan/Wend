# Closed-Beta Mechanics — design brief

Locked 2026-06-08. This rewrites the old itch.io-era brief entirely (that framing is dead:
the target is a **closed Steam beta**, $100 Direct fee paid, no itch/zip distribution).

This doc is **what the beta build contains and tests** — distinct from the Steam *ops*
(App ID / Playtest app creation), which is blocked on identity verification clearing.

---

## Why the beta exists — the three jobs

The beta answers three questions, in priority order:

1. **Is it fun?** The core single-tower mazing loop — is it genuinely compelling, or shallow
   once the novelty fades. This is the load-bearing question; art and bugs are fixable, a
   boring core loop is a design problem.
2. **Does it look professional, not cheap?** The art read — answered by testers who are
   artists and have played enough games to judge.
3. **Does the full networked loop work, and does onboarding land?** The cross-network MP run
   (the one thing that can't be tested solo) + whether a non-SC2 newcomer can get in and through.

---

## The five locked decisions

### 1. Build scope — all three modes, everything unlocked
Campaign (M1–M5), Trials (all five scales), and Ranked all ship in the one build. Each carries
a different job: **Campaign** is the art-read + onboarding surface, **Trials** is the solo
leaderboard loop, **Ranked** is the cross-network MP run that's been blocked on distribution.
One build, one cohort, all three reads at once — if Ranked is broken you hear it from people
you can talk to directly. Nothing is gated/locked inside the build; it's a test, not a ladder.

### 2. Ranked matchmaking — lobby floor 2 for the beta
Production floor is 4 (auto-launch at 8, unanimous-of-present vote at 4–7). With a handful of
friends across timezones you can't reliably get 4 queued at once, and the thing the beta needs
from Ranked — a real networked match + LP/MMR settling with real opponents — only needs **two**
people. So **drop `LOBBY_FLOOR` to 2 for the beta** (vote path stays intact: any two friends
queue → lobby → vote → match → LP settle, exercising the full orchestration at small scale).
**Reverts to 4 at launch** — a one-line constant in `index.js` + `docker compose restart nakama`.

### 3. Feedback — Discord, plus a targeted artist prompt
A **Discord server** is the feedback spine: low-friction, where these people already are,
conversational so bugs/balance/general flow into channels. **It doubles as the community hub**
(closes the open GTM item — built once, not twice). A heavyweight per-session survey, friends
won't fill out; an in-game feedback button is engineering you don't need for five people.

The art read needs structure or it comes back as polite "looks good." Hand the **artists** a
short, pointed prompt that forces them to point at *what* reads cheap, not deliver a verdict:

> **Artist art-read prompt (hand to the artists specifically):**
> 1. First-screen test: in the first 10 seconds, does this read as a finished commercial game
>    or a hobby project? What's the single thing dragging that read down?
> 2. Point at the weakest surface: capsule/title screen, the in-game board, the UI type, the
>    juice/motion, or the color palette. Name the one you'd fix first.
> 3. Where does it look *cheap* specifically — spacing, contrast, fonts, asset consistency,
>    alignment? Be concrete; "it's fine" doesn't help me.
> 4. Where does it already look *right* — what should I not touch?
> 5. If a stranger saw a screenshot, would they assume it costs $10–15 or that it's free?

### 4. Beta data — separate beta season/boards
The beta plays against the **live** backend (same `hil` box). To keep the launch ladder honest,
beta progress lands on a **separate season/board set** — `ranked_s0` + beta-flagged Trials
boards — so launch opens on a **virgin `s1` by construction, with nothing to wipe.** The schema
already parameterizes seasons, so this is a config value, not throwaway architecture. Bonus:
beta data survives for analysis instead of being destroyed. (Beats the alternative — beta on
the real boards + a manual pre-launch wipe — because a forgotten/partial wipe quietly corrupts
the real ladder.)

### 5. Exit criteria — three tiers
- **Continue gate (fun).** Read it *behaviorally*, not verbally — do testers return unprompted,
  play "one more run," talk strategy on their own (the tell that the depth is real)? The honest
  verbal version: *"would you pay $10–15 for this if it weren't mine?"* Fail here and it's a
  design problem — the most important thing the beta can tell you, before a dollar is spent on a
  capsule.
- **Page gate (art).** The artists' read comes back professional (or you've worked through their
  punch-list). This alone **unblocks the public Steam page** — it's the exact insecurity holding it.
- **Launch gate (all four).** Fun confirmed + art good + **≥1 clean full networked Ranked match
  across networks with LP settling correctly** + **a non-SC2 newcomer finishes the campaign**
  without getting stuck + **zero open P0/blocker bugs.**

---

## Cohort spec (falls out of the gates)
The gates can't be read with the wrong people:
- **Fun gate** needs ≥1–2 testers who'd play a maze TD *anyway* (favor-players give polite praise
  and never return unprompted — they can't produce the behavioral signal).
- **Onboarding gate** needs ≥1 tester who is **not** an SC2 / Random TD vet.
- **Ranked launch gate** needs ≥2 who'll get online at the same time across networks.
- **Art gate** needs the artists.

Minimum viable cohort ≈ five people doubling up roles. **Tobe confirms his pool covers it.**

---

## CC / ops items (logged to `notes/open_items.md`)
- **Beta-season flag** in the Nakama board init (`index.js`): create `ranked_s0` + beta-flagged
  Trials boards for the beta so launch's `s1` is untouched.
- **`LOBBY_FLOOR = 2`** for the beta in `index.js`, with a documented **revert to 4 at launch**
  (one constant + `restart nakama`). Don't let it ship to launch at 2.

---

## Out of scope here (deliberately)
- **Steam ops** (App ID, Playtest app, Win+Mac export presets, steampipe) — blocked on identity
  verification; tracked under Steam in STATE/open_items.
- **The cosmetics & collection meta-layer** (catalog, locker/equip, codex, season-pass screen) —
  a separate undesigned arc surfaced 2026-06-08. **Not a beta blocker** (cosmetics sit below the
  fun gate). Next design session, at-the-computer with the art folders.
