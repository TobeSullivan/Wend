extends Node
class_name Pathfinder

const GridScript := preload("res://scripts/grid.gd")

const LOS_STEP_PX := 6.0

const NEIGHBORS_8 := [
	{"d": Vector2i(1, 0),  "cost": 10, "checks": []},
	{"d": Vector2i(-1, 0), "cost": 10, "checks": []},
	{"d": Vector2i(0, 1),  "cost": 10, "checks": []},
	{"d": Vector2i(0, -1), "cost": 10, "checks": []},
	{"d": Vector2i(1, 1),   "cost": 14, "checks": [Vector2i(1, 0), Vector2i(0, 1)]},
	{"d": Vector2i(1, -1),  "cost": 14, "checks": [Vector2i(1, 0), Vector2i(0, -1)]},
	{"d": Vector2i(-1, 1),  "cost": 14, "checks": [Vector2i(-1, 0), Vector2i(0, 1)]},
	{"d": Vector2i(-1, -1), "cost": 14, "checks": [Vector2i(-1, 0), Vector2i(0, -1)]},
]

const NEIGHBORS_4 := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

static func compute_orthogonal_path(start: Vector2i, waypoints: Array, goal: Vector2i, blocked: Dictionary) -> PackedVector2Array:
	var cells: Array = [start]
	var current := start
	var stops: Array = waypoints.duplicate()
	stops.append(goal)
	for next_stop in stops:
		var seg := _astar_4(current, next_stop, blocked)
		if seg.is_empty():
			return PackedVector2Array()
		for i in range(1, seg.size()):
			cells.append(seg[i])
		current = next_stop
	var simple := _collapse_collinear(cells)
	var out := PackedVector2Array()
	for c in simple:
		out.append(GridScript.cell_to_world(c))
	return out

static func _collapse_collinear(cells: Array) -> Array:
	if cells.size() <= 2:
		return cells
	var out: Array = [cells[0]]
	for i in range(1, cells.size() - 1):
		if (cells[i] - cells[i - 1]) != (cells[i + 1] - cells[i]):
			out.append(cells[i])
	out.append(cells[cells.size() - 1])
	return out

static func _astar_4(start: Vector2i, goal: Vector2i, blocked: Dictionary) -> Array:
	if start == goal:
		return [start]
	if not GridScript.in_bounds(start) or not GridScript.in_bounds(goal):
		return []
	var open: Array = [start]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {start: 0}
	var f_score: Dictionary = {start: _manhattan(start, goal)}
	while open.size() > 0:
		var current: Vector2i = _pop_lowest_f(open, f_score)
		if current == goal:
			return _reconstruct(came_from, current)
		for d in NEIGHBORS_4:
			var neighbor: Vector2i = current + d
			if not GridScript.in_bounds(neighbor):
				continue
			if neighbor != goal and neighbor != start and blocked.has(neighbor):
				continue
			var tentative_g: int = (g_score[current] as int) + 10
			if not g_score.has(neighbor) or tentative_g < (g_score[neighbor] as int):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + _manhattan(neighbor, goal)
				if not open.has(neighbor):
					open.append(neighbor)
	return []

static func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return 10 * (absi(a.x - b.x) + absi(a.y - b.y))

static func compute_full_path(start: Vector2i, waypoints: Array, goal: Vector2i, blocked: Dictionary) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(GridScript.cell_to_world(start))
	var current := start
	var stops: Array = waypoints.duplicate()
	stops.append(goal)
	for next_stop in stops:
		var seg := _segment_polyline(current, next_stop, blocked)
		if seg.is_empty():
			return PackedVector2Array()
		for i in range(1, seg.size()):
			pts.append(seg[i])
		current = next_stop
	return pts

static func _segment_polyline(from: Vector2i, to: Vector2i, blocked: Dictionary) -> PackedVector2Array:
	var from_w := GridScript.cell_to_world(from)
	var to_w := GridScript.cell_to_world(to)
	if _line_of_sight(from_w, to_w, blocked):
		return PackedVector2Array([from_w, to_w])
	var cells := _astar_8(from, to, blocked)
	if cells.is_empty():
		return PackedVector2Array()
	var world_pts := PackedVector2Array()
	for c in cells:
		world_pts.append(GridScript.cell_to_world(c))
	return _string_pull(world_pts, blocked)

static func _line_of_sight(a: Vector2, b: Vector2, blocked: Dictionary) -> bool:
	var d := a.distance_to(b)
	var steps: int = maxi(2, int(d / LOS_STEP_PX))
	for i in range(1, steps):
		var t := float(i) / float(steps)
		var p: Vector2 = a.lerp(b, t)
		var cell := GridScript.world_to_cell(p)
		if blocked.has(cell):
			return false
	return true

static func _astar_8(start: Vector2i, goal: Vector2i, blocked: Dictionary) -> Array:
	if start == goal:
		return [start]
	if not GridScript.in_bounds(start) or not GridScript.in_bounds(goal):
		return []
	var open: Array = [start]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {start: 0}
	var f_score: Dictionary = {start: _octile(start, goal)}

	while open.size() > 0:
		var current: Vector2i = _pop_lowest_f(open, f_score)
		if current == goal:
			return _reconstruct(came_from, current)
		for n in NEIGHBORS_8:
			var d: Vector2i = n.d
			var neighbor: Vector2i = current + d
			if not GridScript.in_bounds(neighbor):
				continue
			if neighbor != goal and neighbor != start and blocked.has(neighbor):
				continue
			var corner_blocked := false
			for c in n.checks:
				if blocked.has(current + c):
					corner_blocked = true
					break
			if corner_blocked:
				continue
			var tentative_g: int = (g_score[current] as int) + (n.cost as int)
			if not g_score.has(neighbor) or tentative_g < (g_score[neighbor] as int):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + _octile(neighbor, goal)
				if not open.has(neighbor):
					open.append(neighbor)
	return []

static func _string_pull(pts: PackedVector2Array, blocked: Dictionary) -> PackedVector2Array:
	if pts.size() <= 2:
		return pts
	var result := PackedVector2Array()
	result.append(pts[0])
	var anchor := 0
	for i in range(1, pts.size() - 1):
		if not _line_of_sight(pts[anchor], pts[i + 1], blocked):
			result.append(pts[i])
			anchor = i
	result.append(pts[pts.size() - 1])
	return result

static func _octile(a: Vector2i, b: Vector2i) -> int:
	var dx: int = absi(a.x - b.x)
	var dy: int = absi(a.y - b.y)
	return 14 * mini(dx, dy) + 10 * (maxi(dx, dy) - mini(dx, dy))

static func _pop_lowest_f(open: Array, f_score: Dictionary) -> Vector2i:
	var best_idx := 0
	var best_f: int = f_score.get(open[0], 0x7fffffff)
	for i in range(1, open.size()):
		var f: int = f_score.get(open[i], 0x7fffffff)
		if f < best_f:
			best_f = f
			best_idx = i
	var cell: Vector2i = open[best_idx]
	open.remove_at(best_idx)
	return cell

static func _reconstruct(came_from: Dictionary, current: Vector2i) -> Array:
	var path: Array = [current]
	while came_from.has(current):
		current = came_from[current]
		path.push_front(current)
	return path
