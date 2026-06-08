# Polish / Bug Punch-list

Repo path: `notes/polish_punchlist.md`
Source: 2026-06-07 in-game review (Tobe). These are CC tasks unless noted. Items 5 and 6 are resolved by the in-match HUD design; the rest are open.

---

1. **White corner artifacts (home / main menu).** Bottom corners show a few px of white, reads like the screen has rounded corners. Tiny but wrong — track down and remove. **(2026-06-08) The in-game board corners did NOT reproduce in the rail-rebuild capture** (the board edge frame reads clean) — may have been tied to the old full-bleed-ish layout, or is subtle/resolution-dependent. The home/menu corners are still open (separate surface).

2. **Text too thin.** Fredoka's variable-font default weight is Light (300), and "set bold" silently no-ops in Godot. Fix per `design/VISUAL_SYSTEM.md`: ship a static **Fredoka-SemiBold.ttf** and point the project default font at it (most reliable), or `variation_embolden`. Promote weight + outline to a shared `Theme` so it can't regress screen-by-screen.

3. **Em-dashes in strings.** Literal "—" appears in UI strings (e.g. "Trials — daily/weekly"), reads unnatural. Sweep all user-facing strings and remove/replace. **(2026-06-08) Specific drift found: `design/VISUAL_SYSTEM.md` PVE-select section still says "em-dash if unplayed" for an empty best-score — that's a user-facing string. Use "no score yet" (as in `notes/mockups/meta_menu_mock.html`).**

4. ✅ **Speed bug + speed rules.** RESOLVED in the rail rebuild (2026-06-08): the rail's Speed button is `disabled` during build (greyed) and active in run only, and `_sync_ff_to_engine()` initializes the speed index from the actual `Engine.time_scale` so the label can't desync from the applied speed.

5. ✅ **Remove the "hide" button on tower info.** RESOLVED — the rewritten `tower_drawer.gd` is contextual (no hide button, no collapse tab).

6. ✅ **In-game layout rework.** IMPLEMENTED (2026-06-08, CC) — reserved right rail (`rail.gd`) + maximized 25×16 board + tower info that docks in the rail's lower gap (with an over-board overlay fallback on short windows). Built against `design/INMATCH_HUD.md` + the `inmatch_assembly.html` mock; verified by windowed capture. Retired `hud.gd` + `action_strip.gd`. (The board white-corner artifact #1 did NOT reproduce in capture — see #1.)

7. ✅ **Victory screen star tiles.** RESOLVED (2026-06-08, CC) — the campaign result screen (`match_end_panel.gd`) was rebuilt to `notes/mockups/victory_screen_mock.html`: an angled gold VICTORY hero overlapping the dimmed board, three **square star tiles with a full clean outline** (gold earned / card empty — the corner-only-outline look is gone), the DAMAGE score, and leave-only **Next map / Trials / Ranked** buttons (also resolves the campaign M1-win-flow follow-up). PVE-Trials/PVP/ranked/eliminated keep their card layout (out of the mock's scope). Static composition; the staged reveal (cascade/pop/tick) is the later juice pass. Verified by windowed capture.

8. ✅ **Build mode — out of supply.** RESOLVED (2026-06-08, CC) — `build_controller`: when `towers.size() >= max_towers`, the mouse-hover placement ghost is hidden (and not shown on build-mode entry); it reappears if the player sells a tower. Touch already declined to park a preview when full.

9. **Campaign rework + hand-authoring editor.**
   - ✅ **Grid editor BUILT** (`notes/tools/map_editor.html`, 2026-06-08) — 25×16, paints board / obstacle / tower-ghost / ordered checkpoints + entry/exit + resizable bonus-zone circles (radius from the locked formula), validates a legal entry→checkpoints→exit path, imports an existing `.tres` losslessly (beats preserved), saves real `mission_NN.tres`.
   - ✅ **M1–M5 re-authored + tutorial copy reviewed** (2026-06-08) — new hand-built mazes, reviewed beat copy (undead framing, no em-dashes, 1/2/3-star not medals, several beats cut), correct names. Mission 1 now has its 1 checkpoint (the old 0-checkpoint bug is moot).
   - ⏳ **CC follow-ups** (see `STATE.md` → Next step): ghost outline clears when the player builds off-suggestion; M3 outline rides its single load beat; keep threshold fields (1/2/3-star, not bronze/silver/gold); M1 win flow = leave-only → next map / Trials / Ranked; `grid_size` default → 25×16; anchor resolve check in the new HUD.
   - ⏳ **Tooltips/tips dismissable-only** — still open (CC): make tutorial callouts user-dismissable, not auto-dismiss toasts.
