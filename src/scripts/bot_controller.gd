extends Node
class_name BotController

const PathfinderScript := preload("res://scripts/pathfinder.gd")

const ACTION_INTERVAL := 0.2
const SAMPLE_K := 8
const MERGE_DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var board
var ctrl
var coordinator
var difficulty: float = 1.0

var _accum := 0.0

func _process(delta: float) -> void:
	if coordinator == null or board == null or ctrl == null:
		return
	if coordinator.phase != "build" or coordinator.match_over:
		return
	if not board.is_active():
		return
	_accum += delta
	if _accum < ACTION_INTERVAL:
		return
	if not coordinator.try_consume_bot_action():
		return
	_accum = 0.0
	_take_one_action()

func _take_one_action() -> void:
	if ctrl.towers.size() < _target_towers() and board.can_afford(GameConstants.TOWER_COST):
		var cell = _best_maze_cell()
		if cell != null and ctrl.bot_place_tower(cell):
			return
	if _try_merge():
		return
	if coordinator.is_pvp:
		coordinator.set_board_ready(board, true)

func _target_towers() -> int:
	var t := int((6 + coordinator.round_num * 3) * difficulty)
	return mini(t, ctrl.max_towers)

func _best_maze_cell():
	var cands := _candidate_cells()
	if cands.is_empty():
		return null
	cands.shuffle()
	var sample: Array = cands.slice(0, mini(SAMPLE_K, cands.size()))
	var base_len := _current_path_len()
	var best = null
	var best_len := base_len
	var first_valid = null
	for c in sample:
		var l := _trial_len(c)
		if l < 0.0:
			continue
		if first_valid == null:
			first_valid = c
		if l > best_len:
			best_len = l
			best = c
	return best if best != null else first_valid

func _candidate_cells() -> Array:
	var sources: Array = ctrl.blocked.keys()
	if sources.is_empty():
		sources = [ctrl.entry_cell, ctrl.exit_cell]
		sources.append_array(ctrl.checkpoint_cells)
	var seen := {}
	var out: Array = []
	for s in sources:
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = s + d
			if seen.has(n):
				continue
			seen[n] = true
			if _cell_placeable(n):
				out.append(n)
	return out

func _cell_placeable(cell: Vector2i) -> bool:
	if ctrl.towers.size() >= ctrl.max_towers:
		return false
	if cell.x < 0 or cell.y < 0 or cell.x >= ctrl.grid_size.x or cell.y >= ctrl.grid_size.y:
		return false
	if ctrl.blocked.has(cell):
		return false
	if cell == ctrl.entry_cell or cell == ctrl.exit_cell:
		return false
	for cp in ctrl.checkpoint_cells:
		if cell == cp:
			return false
	return true

func _current_path_len() -> float:
	var path: PackedVector2Array = PathfinderScript.compute_full_path(
		ctrl.entry_cell, ctrl.checkpoint_cells, ctrl.exit_cell, ctrl.blocked)
	return _polyline_len(path)

func _trial_len(cell: Vector2i) -> float:
	if not _cell_placeable(cell):
		return -1.0
	var trial: Dictionary = ctrl.blocked.duplicate()
	trial[cell] = true
	var path: PackedVector2Array = PathfinderScript.compute_full_path(
		ctrl.entry_cell, ctrl.checkpoint_cells, ctrl.exit_cell, trial)
	if path.is_empty():
		return -1.0
	return _polyline_len(path)

func _polyline_len(path: PackedVector2Array) -> float:
	var l := 0.0
	for i in range(1, path.size()):
		l += path[i - 1].distance_to(path[i])
	return l

func _try_merge() -> bool:
	# Climb the tier ladder by merging any adjacent same-tier pair (lowest tier first).
	var best_src = null
	var best_dst: Vector2i = Vector2i.ZERO
	var best_tier := GameConstants.MAX_TIER + 1
	for t in ctrl.towers:
		if not is_instance_valid(t) or t.tier >= GameConstants.MAX_TIER:
			continue
		for d in MERGE_DIRS:
			var other = ctrl._tower_at_cell(t.grid_cell + d)
			if other != null and other.tier == t.tier and t.tier < best_tier:
				best_tier = t.tier
				best_src = t
				best_dst = t.grid_cell + d
	if best_src == null:
		return false
	return ctrl._try_merge(best_src.grid_cell, best_dst)
