extends Node
class_name TaskCatalog

const MapResourceScript := preload("res://resources/map_resource.gd")

const SHAPES := ["towers", "zones", "kills", "games", "score"]
const CADENCES := ["daily", "weekly", "monthly"]

const SHAPE_LABEL := {
	"towers": "Build towers",
	"zones": "Build inside zones",
	"kills": "Get kills",
	"games": "Play games",
	"score": "Reach score",
}
const CADENCE_LABEL := {"daily": "Daily", "weekly": "Weekly", "monthly": "Monthly"}

const PAYOUTS := {"daily": 120, "weekly": 600, "monthly": 2400}

const THRESHOLDS := {
	"daily":   {"towers": 20,  "zones": 6,   "kills": 200,  "games": 3,  "score": 2_000_000},
	"weekly":  {"towers": 100, "zones": 30,  "kills": 1000, "games": 15, "score": 10_000_000},
	"monthly": {"towers": 400, "zones": 120, "kills": 4000, "games": 60, "score": 40_000_000},
}

static func _zero_progress() -> Dictionary:
	var p := {}
	for shape in SHAPES:
		p[shape] = 0
	return p

static func fresh_state() -> Dictionary:
	var windows := {}
	var progress := {}
	var completed := {}
	for c in CADENCES:
		windows[c] = ""
		progress[c] = _zero_progress()
		completed[c] = []
	return {"windows": windows, "progress": progress, "completed": completed}

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

static func roll_windows(state: Dictionary, keys: Dictionary) -> void:
	_ensure(state)
	for c in CADENCES:
		var current := String(keys.get(c, ""))
		if current != "" and String(state["windows"][c]) != current:
			state["progress"][c] = _zero_progress()
			state["completed"][c] = []
			state["windows"][c] = current

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

static func _match_increment(stats: Dictionary) -> Dictionary:
	return {
		"towers": int(stats.get("towers", 0)),
		"zones": int(stats.get("zones", 0)),
		"kills": int(stats.get("kills", 0)),
		"games": 1,
		"score": int(stats.get("score", 0)),
	}

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

static func record_match(stats: Dictionary) -> Dictionary:
	var state := SaveData.tasks()
	roll_windows(state, current_keys())
	var res := accumulate(state, _match_increment(stats))
	if int(res["points"]) > 0:
		SaveData.add_season_points(int(res["points"]))
	else:
		SaveData.save()
	return res
