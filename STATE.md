# State — Wend
Last updated: 2026-06-09

## Read order
`claude-rules.md` → `RULES.md` → this file → `notes/open_items.md` (open backlog) →
`notes/decisions.md` (locked calls, don't re-litigate) → only the specific file the task needs.
History/log lives in `STATE_ARCHIVE.md` — reference only, don't load unless digging into a past decision.

## Current focus
Cosmetics designed end to end (2026-06-09): catalogue + per-slot curation + season track + task
system + rank-sticker slot all locked (`design/COSMETICS.md`, `design/SEASON.md`,
`notes/task_system.md`, `notes/asset_catalog.md`, `notes/asset_buy_list.md`). Build/implementation
queue is otherwise clear (juice complete, polish closed, MP + ranked + anti-cheat spine done). The
only hard gate is Steam identity verification clearing → then create the Wend App ID + Playtest app.

## Last session (2026-06-09, design — cosmetics catalogue + curation + season/tasks + stickers)
Closed the cosmetics contents work. Catalogue built from a real store scrape (two stdlib scripts in
`notes/tools/`) → curated into `asset_catalog.md` + `asset_buy_list.md` (towers cost $0, all owned;
Tier 1 core ~$69). Per-slot curation locked against the real art. New design locked: runtime-tint
rule (tier-as-color free on outline/single-hue art, multi-color sprites stay authored recolors,
Masters = animated stroke); supply-driven reward economy (finite ~8 tower skins are the long-term
limiter; one tower milestone/season); Season XP = tasks not playing; Ranked bundle = Title + Frame +
Rank Sticker (prestige, off-track); board-sticker chrome slot. `design/SEASON.md` (30-tier track) +
`notes/task_system.md` (5 shapes × 3 cadences) are new. No CC blockers added.

## Next step
1. **Steam (blocked on verification):** identity verification clears → create the Wend App ID →
   create the Playtest app (confidential/friends-only; hidden page, manual keys). Confirm the entity
   type chosen at registration. See `notes/open_items.md` → Steam.
2. **Human 2-client E2E (Steam-gated):** two real clients Find Match → matchmake → forming lobby →
   vote → full networked match across networks. Every link is verified individually; this is the
   all-the-way manual run, and the ranked loop's first real exercise (LP/MMR settle, Surface 2).
3. **Next design session (at-computer):** the cosmetics open forks (score task cumulative-vs-best;
   active task count) + finalize season-pass numbers now the catalogue/slots exist.
4. **CC, carried (not blocking):** beta-season boards + `LOBBY_FLOOR=2` in `index.js`; catapult PNG
   export; import alt mobs/biomes; board-sticker render layer; `rescale_campaign.gd` still targets
   25×14 (should be 25×16). See `notes/open_items.md`.

## Recently touched files
- `design/COSMETICS.md` — rewritten (supply principle, runtime-tint rule, board-sticker slot, Ranked bundle)
- `design/SEASON.md`, `notes/task_system.md`, `notes/asset_catalog.md`, `notes/asset_buy_list.md`, `notes/gds_catalog.csv`, `notes/tools/gds_catalog.py`, `notes/tools/gds_sheets.py` — last session's cosmetics batch
- **This session (audit/hygiene):** `STATE.md` trimmed + `STATE_ARCHIVE.md` (old STATE snapshot archived) + `notes/open_items.md` (now open-only) + `notes/decisions.md` (NEW locks doc) + drift fixes in `design/DESIGN_MODES.md`, `design/CAMPAIGN.md`, `design/VISUAL_SYSTEM.md`, `notes/multiplayer_architecture.md`; deleted `notes/wrap.md`

## Open questions / blocked on
- **Steam:** identity verification pending (2–7 biz days from 2026-06-07) — blocks App ID + Playtest. Confirm entity type chosen at registration.
- **Cosmetics open forks:** score task cumulative-vs-best-run; active task count (15 vs rotating). Confirm the free Background Creator pack yields path tiles before relying on it for board.
- **Blocked on playtest data:** star-threshold calibration; economy/supply retune for 25×16; campaign tuning integers; PVP seed-convergence eyeball.
- Full open backlog in `notes/open_items.md`.
