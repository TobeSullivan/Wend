extends Node
class_name TaskCatalog

# Preloaded under the *Script alias the rest of the project uses (cycle-safe; never the bare
# class_name) — only for its WindowType enum, to key task windows like the Trials boards.
const MapResourceScript := preload("res://resources/map_resource.gd")

# The season XP source (notes/task_system.md, locked 2026-06-09, forks closed 2026-06-10).
# Tasks are the ONLY way to earn season points — you earn XP from tasks, not from playing
# (the old "complete a match" point source is gone). Points feed SaveData.season_points(),
# which drives the 30-tier track (CosmeticsCatalog / the Season screen).
#
# Design (do not re-litigate — notes/decisions.md + task_system.md):
#   - Five FIXED task shapes, identical at every cadence: build towers, build inside zones,
#     get kills, play games, reach score (score is CUMULATIVE across the window, not best run).
#   - Three cadences (daily / weekly / monthly); all 15 tasks active at once — no rotation.
#   - Progress counts in Trials OR Ranked only (campaign + casual excluded — wired in
#     scene_manager). One match feeds every cadence's counters at once.
#   - Payout chain: ×5 daily→weekly, ×4 weekly→monthly (120 / 600 / 2,400 per task).
#
# This file owns the schema + the pure roll/accumulate/award logic so it stays unit-testable
# without time or the save file. SaveData holds only the raw `tasks` blob (catalog-agnostic,
# like the cosmetics store); the glue at the bottom reads/writes it. Window keys reuse
# LeaderboardService.window_date so task resets land on the SAME daily/weekly/monthly
# boundaries as the Trials boards — one definition of "this window" across the app.

# Stat keys = the five shapes. "games" has no match-supplied count (always +1 per match).
const SHAPES := ["towers", "zones", "kills", "games", "score"]
const CADENCES := ["daily", "weekly", "monthly"]

# Human labels for a future task panel / post-match nudge (notes/open_items).
const SHAPE_LABEL := {
	"towers": "Build towers",
	"zones": "Build inside zones",
	"kills": "Get kills",
	"games": "Play games",
	"score": "Reach score",
}
const CADENCE_LABEL := {"daily": "Daily", "weekly": "Weekly", "monthly": "Monthly"}

# Payout per completed task (task_system.md). ×5 daily→weekly, ×4 weekly→monthly.
const PAYOUTS := {"daily": 120, "weekly": 600, "monthly": 2400}

# Absolute thresholds (the "X" in "build X towers"). PLAYTEST-GATED STAND-INS — the open
# item is "absolute task thresholds, tune with star thresholds" (notes/open_items.md). The
# STRUCTURE is locked; only these integers move once playtest data exists. Roughly ×5 / ×4
# up the cadences, matching the payout chain. Score is total damage dealt (millions-scale).
const THRESHOLDS := {
	"daily":   {"towers": 20,  "zones": 6,   "kills": 200,  "games": 3,  "score": 2_000_000},
	"weekly":  {"towers": 100, "zones": 30,  "kills": 1000, "games": 15, "score": 10_000_000},
	"monthly": {"towers": 400, "zones": 120, "kills": 4000, "games": 60, "score": 40_000_000},
}

# ============================================================================
# Pure schema + math (no globals, no time — exercised directly by the test harness)
# ============================================================================

static func _zero_progress() -> Dictionary:
	var p := {}
	for shape in SHAPES:
		p[shape] = 0
	return p

# A complete, freshly-seeded task state. Window keys empty so the first record_match rolls
# every cadence into its current window.
static func fresh_state() -> Dictionary:
	var windows := {}
	var progress := {}
	var completed := {}
	for c in CADENCES:
		windows[c] = ""
		progress[c] = _zero_progress()
		completed[c] = []
	return {"windows": windows, "progress": progress, "completed": completed}

# Backfill any missing keys so a partial/empty blob (or one from an older build) becomes a
# full state in place. SaveData seeds only `{}`, so normalization lives here — the single
# owner of the schema.
static func _ensure(state: Dictionary) -> void:
	for key in ["windows", "progress", "completed"]:
		if typeof(state.get(key)) != TYPE_DICTIONARY:
			state[key] = {}
	for c in CADENCES:
		if typeof(state["progress"].get(c)) != TYPE_DICTIONARY:
			state["progress"][c] = _zero_progress()
		else:
			for shape in SHAPES:
				if not state["progress"][c].has(shape):
					state["progress"][c][shape] = 0
		if typeof(state["completed"].get(c)) != TYPE_ARRAY:
			state["completed"][c] = []
		if not state["windows"].has(c):
			state["windows"][c] = ""

# Roll any cadence whose stored window key no longer matches the current one: zero its
# progress + clear its completed set so the new window starts fresh. Pure — `keys` is the
# {cadence: current_window_key} map supplied by the caller.
static func roll_windows(state: Dictionary, keys: Dictionary) -> void:
	_ensure(state)
	for c in CADENCES:
		var current := String(keys.get(c, ""))
		if current != "" and String(state["windows"][c]) != current:
			state["progress"][c] = _zero_progress()
			state["completed"][c] = []
			state["windows"][c] = current

# Add one match's stats to every cadence's counters, then award the payout for any task that
# crossed its threshold this window for the first time. Returns {points, completed} where
# completed is a list of {cadence, shape} just finished. Assumes windows are already rolled.
static func accumulate(state: Dictionary, incr: Dictionary) -> Dictionary:
	_ensure(state)
	var points := 0
	var completed_now: Array = []
	for c in CADENCES:
		var prog: Dictionary = state["progress"][c]
		var done: Array = state["completed"][c]
		for shape in SHAPES:
			prog[shape] = int(prog[shape]) + int(incr.get(shape, 0))
			if not done.has(shape) and int(prog[shape]) >= int(THRESHOLDS[c][shape]):
				done.append(shape)
				points += int(PAYOUTS[c])
				completed_now.append({"cadence": c, "shape": shape})
	return {"points": points, "completed": completed_now}

# Convert a match-stats dict ({towers, zones, kills, score}) into a per-shape increment.
# "games" is always +1 — one match played.
static func _match_increment(stats: Dictionary) -> Dictionary:
	return {
		"towers": int(stats.get("towers", 0)),
		"zones": int(stats.get("zones", 0)),
		"kills": int(stats.get("kills", 0)),
		"games": 1,
		"score": int(stats.get("score", 0)),
	}

# Flat list for a task panel / inspection: one entry per cadence×shape with its progress,
# threshold, payout and done flag. Read-only; ensures the state first.
static func task_list(state: Dictionary) -> Array:
	_ensure(state)
	var out: Array = []
	for c in CADENCES:
		for shape in SHAPES:
			out.append({
				"cadence": c, "shape": shape,
				"label": "%s %d" % [SHAPE_LABEL[shape], int(THRESHOLDS[c][shape])],
				"progress": int(state["progress"][c][shape]),
				"target": int(THRESHOLDS[c][shape]),
				"payout": int(PAYOUTS[c]),
				"done": (state["completed"][c] as Array).has(shape),
			})
	return out

# ============================================================================
# Glue: the live save state + real window keys (uses the SaveData / LeaderboardService
# globals — safe autoload/static refs, never a class_name preload)
# ============================================================================

# {cadence: window_key} for right now, keyed identically to the Trials boards (same daily/
# weekly/monthly boundaries via LeaderboardService.window_date).
static func current_keys() -> Dictionary:
	var window_type := {
		"daily": MapResourceScript.WindowType.DAILY,
		"weekly": MapResourceScript.WindowType.WEEKLY,
		"monthly": MapResourceScript.WindowType.MONTHLY,
	}
	var keys := {}
	for c in CADENCES:
		keys[c] = LeaderboardService.window_date(window_type[c])
	return keys

# Record one completed Trials/Ranked match: roll expired windows, add the stats, award any
# newly-completed tasks into season points, and persist. Returns the accumulate() summary
# ({points, completed}) for the caller (post-match nudge later). Call site decides which
# modes count — this never sees campaign/casual.
static func record_match(stats: Dictionary) -> Dictionary:
	var state := SaveData.tasks()
	roll_windows(state, current_keys())
	var res := accumulate(state, _match_increment(stats))
	# add_season_points persists the whole save (incl. the mutated tasks blob). When nothing
	# was awarded, still write through so accumulated progress survives a quit.
	if int(res["points"]) > 0:
		SaveData.add_season_points(int(res["points"]))
	else:
		SaveData.save()
	return res
