extends RefCounted
class_name GhostLadder

enum State { NAMED_TIER, GHOST, YOUR_BEST, TOP }

var bronze: int = 0
var silver: int = 0
var gold: int = 0

var ghosts: Array = []

var own_best: int = 0

var _ghost_rungs: Array = []
var _window: int = 0
var _tier: int = 1
var _group: String = "solo"

func setup(bronze_t: int, silver_t: int, gold_t: int, ghost_list: Array, best: int) -> void:
	bronze = bronze_t
	silver = silver_t
	gold = gold_t
	own_best = best
	set_ghosts(ghost_list)

func set_ghosts(ghost_list: Array) -> void:
	ghosts = ghost_list.duplicate(true)
	_ghost_rungs = []
	for g in ghosts:
		if int(g.get("score", 0)) > gold:
			_ghost_rungs.append(g)
	_ghost_rungs.sort_custom(func(a, b): return int(a["score"]) < int(b["score"]))

func configure_fetch(window: int, tier: int, group: String) -> void:
	_window = window
	_tier = tier
	_group = group

func fetch_ghosts_async() -> void:
	var data = await LeaderboardService.trials_board(_window, _tier, _group)
	if typeof(data) != TYPE_DICTIONARY:
		return
	var gl: Array = []
	for e in data.get("entries", []):
		var nm := String(e.get("name", ""))
		var rnd := LeaderboardService.round_part(int(e.get("score", 0)))
		if nm != "" and rnd > 0:
			gl.append({"name": nm, "score": rnd})
	set_ghosts(gl)

func target_for(score: int) -> Dictionary:
	if gold > 0 and score < gold:
		if bronze > 0 and score < bronze:
			return {"state": State.NAMED_TIER, "target": bronze, "label": "Bronze", "name": ""}
		if silver > 0 and score < silver:
			return {"state": State.NAMED_TIER, "target": silver, "label": "Silver", "name": ""}
		return {"state": State.NAMED_TIER, "target": gold, "label": "Gold", "name": ""}
	for g in _ghost_rungs:
		if int(g["score"]) > score:
			return {"state": State.GHOST, "target": int(g["score"]), "label": "GHOST", "name": str(g["name"])}
	if own_best > score:
		return {"state": State.YOUR_BEST, "target": own_best, "label": "YOUR BEST", "name": ""}
	return {"state": State.TOP, "target": 0, "label": "TOP", "name": ""}

func passed(score: int) -> int:
	var n := 0
	for t in [bronze, silver, gold]:
		if t > 0 and score >= t:
			n += 1
	for g in _ghost_rungs:
		if score >= int(g["score"]):
			n += 1
	return n

func rung_count() -> int:
	var n := 0
	for t in [bronze, silver, gold]:
		if t > 0:
			n += 1
	return n + _ghost_rungs.size()

func rungs_above(score: int, n: int = 3) -> Array:
	var out: Array = []
	var tiers := [bronze, silver, gold]
	for i in range(3):
		var t: int = tiers[i]
		if t > 0 and score < t:
			out.append({"kind": "star", "label": "%d star" % (i + 1), "target": t, "stars": i + 1, "name": ""})
	for g in _ghost_rungs:
		if int(g["score"]) > score:
			out.append({"kind": "ghost", "label": str(g["name"]), "target": int(g["score"]), "stars": 0, "name": str(g["name"])})
	if own_best > score and own_best > gold:
		out.append({"kind": "your_best", "label": "Your best", "target": own_best, "stars": 0, "name": ""})
	out.sort_custom(func(a, b): return int(a["target"]) < int(b["target"]))
	if out.size() > n:
		out = out.slice(0, n)
	return out
