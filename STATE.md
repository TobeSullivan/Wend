# State — Wend
Last updated: 2026-06-10

## Read order
`claude-rules.md` → `RULES.md` → this file → `notes/open_items.md` (open backlog) →
`notes/decisions.md` (locked calls, don't re-litigate) → only the specific file the task needs.
History/log lives in `STATE_ARCHIVE.md` — reference only, don't load unless digging into a past decision.

## Current focus
Season-pass design fully locked (2026-06-10): point economy, payout chain, S1 tier map, task
system forks. MP arch doc drift resolved. Build queue clear. Hard gate remains Steam identity
verification → App ID → Playtest app.

## Last session (2026-06-10, design — season-pass numbers + MP arch drift)
Locked the season-pass economy: 30 tiers × 1,000 pts, 8wk, payout chain 120/600/2,400
(×5 daily→weekly, ×4 weekly→monthly). Ceiling ~81,600 vs 30,000 track (~37% capture).
Trials placement bonus: 100/250/500. Task forks closed: score = cumulative, all 15 active.
S1 tier map locked (30-row item table, ~$23 forced spend, all milestone towers $0/owned).
`notes/multiplayer_architecture.md` drift resolved: banner added + two verdict cells fixed
(Steam-relay → "skipped"; Dedicated → "deployed").

## Next step
1. **Steam (blocked on verification):** clears → create Wend App ID → create Playtest app
   (confidential/friends-only; hidden page, manual keys). Confirm entity type at registration.
2. **Human 2-client E2E (Steam-gated):** two real clients Find Match → matchmake → lobby →
   vote → full networked match across networks. First real exercise of the ranked loop.
3. **CC, carried:** beta-season boards + `LOBBY_FLOOR=2` in `index.js`; catapult PNG export;
   import alt mobs/biomes; board-sticker render layer; `rescale_campaign.gd:18` targets 25×14
   (should be 25×16). See `notes/open_items.md`.
4. **Design (own session):** finalize season-pass absolute threshold integers once playtest
   data exists. `notes/season_pass.md` open section tracks this.

## Recently touched files
- `notes/season_pass.md` — rewritten (locked numbers, payout chain, "complete a match" removed)
- `design/SEASON.md` — forks closed + S1 tier map added
- `notes/task_system.md` — forks closed, payouts added
- `notes/multiplayer_architecture.md` — banner + two verdict cells fixed

## Open questions / blocked on
- **Steam:** identity verification pending (2–7 biz days from 2026-06-07). Confirm entity type.
- **Absolute task thresholds** (the X integers) — playtest-gated.
- **Background Creator pack:** confirm it yields path tiles before relying on it for the board slot.
- Full open backlog in `notes/open_items.md`.
