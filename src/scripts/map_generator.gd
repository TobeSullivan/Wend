extends Node

const MapResourceScript := preload("res://resources/map_resource.gd")
const ZoneDefinitionScript := preload("res://resources/zone_definition.gd")
const ObstacleDefinitionScript := preload("res://resources/obstacle_definition.gd")
const ObstaclePropsScript := preload("res://resources/obstacle_props.gd")
const GridScript := preload("res://scripts/grid.gd")
const PathfinderScript := preload("res://scripts/pathfinder.gd")
const BonusZoneScript := preload("res://scripts/bonus_zone.gd")

const SCALE_TABLE := {
	1: {"supply": 20,  "checkpoints": [1, 1], "zones": [1, 2], "mobs": 8,  "rounds": [10, 13]},
	2: {"supply": 40,  "checkpoints": [1, 2], "zones": [2, 3], "mobs": 12, "rounds": [13, 17]},
	3: {"supply": 60,  "checkpoints": [2, 2], "zones": [3, 4], "mobs": 16, "rounds": [17, 21]},
	4: {"supply": 80,  "checkpoints": [2, 3], "zones": [4, 5], "mobs": 20, "rounds": [21, 26]},
	5: {"supply": 100, "checkpoints": [3, 3], "zones": [5, 6], "mobs": 24, "rounds": [26, 30]},
}

const MIN_PATH_RATIO := 1.35
const THRESHOLD_COVERAGE := 0.5

static func generate(map_seed: int, scale_tier: int, mode: int, window_type: int = 0, window_date: String = ""):
	var tier: int = clampi(scale_tier, 1, 5)
	var params: Dictionary = SCALE_TABLE[tier]
	var rng := RandomNumberGenerator.new()
	rng.seed = map_seed

	var cols := GridScript.COLS
	var rows := GridScript.ROWS

	var map: Variant = MapResourceScript.new()
	map.map_seed = map_seed
	map.mode = mode
	map.scale_tier = tier
	map.window_type = window_type
	map.window_date = window_date
	map.grid_size = Vector2i(cols, rows)
	map.supply_cap = params.supply
	map.mob_count = params.mobs
	map.round_count = rng.randi_range(params.rounds[0], params.rounds[1])

	map.entry_cell = Vector2i(0, rng.randi_range(int(rows * 0.3), int(rows * 0.7)))
	map.exit_cell = Vector2i(cols - 1, rng.randi_range(int(rows * 0.3), int(rows * 0.7)))

	var n_cp: int = rng.randi_range(params.checkpoints[0], params.checkpoints[1])
	var straight: float = GridScript.cell_to_world(map.entry_cell).distance_to(GridScript.cell_to_world(map.exit_cell))
	var best_cps: Array[Vector2i] = []
	var best_len := -1.0
	for _attempt in range(12):
		var cps := _place_checkpoints(rng, n_cp, cols, rows)
		var plen := _path_length(_compute_path(map.entry_cell, cps, map.exit_cell, {}))
		if plen > best_len:
			best_len = plen
			best_cps = cps
		if plen >= straight * MIN_PATH_RATIO:
			break
	map.checkpoint_cells = best_cps

	var reserved := {}
	reserved[map.entry_cell] = true
	reserved[map.exit_cell] = true
	for cp in map.checkpoint_cells:
		reserved[cp] = true

	var blocked := {}
	var obstacles: Array = []
	var target_cells: int = rng.randi_range(tier * 2, tier * 3 + 1)
	var placed_cells := 0
	var tries := 0
	while placed_cells < target_cells and tries < target_cells * 12:
		tries += 1
		var remaining := target_cells - placed_cells
		var max_dim: int = 4 if remaining >= 4 else (2 if remaining >= 3 else 1)
		var fp: Vector2i = ObstaclePropsScript.pick_footprint(rng, max_dim)
		var origin := Vector2i(rng.randi_range(3, cols - 4 - (fp.x - 1)), rng.randi_range(1, rows - 2 - (fp.y - 1)))
		var fcells: Array = []
		var clear := true
		for dx in range(fp.x):
			for dy in range(fp.y):
				var c := origin + Vector2i(dx, dy)
				if reserved.has(c) or blocked.has(c):
					clear = false
				fcells.append(c)
		if not clear:
			continue
		for c in fcells:
			blocked[c] = true
		if _compute_path(map.entry_cell, map.checkpoint_cells, map.exit_cell, blocked).is_empty():
			for c in fcells:
				blocked.erase(c)
			continue
		var d: Variant = ObstacleDefinitionScript.new()
		d.prop_id = ""
		d.origin = origin
		d.footprint = fp
		obstacles.append(d)
		placed_cells += fcells.size()
	map.obstacles = obstacles

	map.bonus_zones = _place_zones(rng, map, params, blocked, cols, rows)

	if mode != MapResourceScript.Mode.PVP:
		_derive_thresholds(map, best_len)

	return map

static func _place_checkpoints(rng: RandomNumberGenerator, n: int, cols: int, rows: int) -> Array[Vector2i]:
	var cps: Array[Vector2i] = []
	var attempts := 0
	while cps.size() < n and attempts < 80:
		attempts += 1
		var cand := Vector2i(rng.randi_range(3, cols - 4), rng.randi_range(1, rows - 2))
		var ok := true
		for e in cps:
			if absi(e.x - cand.x) < 4 and absi(e.y - cand.y) < 3:
				ok = false
				break
		if ok:
			cps.append(cand)
	return cps

static func _place_zones(rng: RandomNumberGenerator, map, params: Dictionary, blocked: Dictionary, cols: int, rows: int) -> Array:
	var zones: Array = []
	var n_zones: int = rng.randi_range(params.zones[0], params.zones[1])

	var path := _compute_path(map.entry_cell, map.checkpoint_cells, map.exit_cell, blocked)
	if path.size() >= 2:
		var mid: Vector2 = path[path.size() / 2]
		var cell := GridScript.world_to_cell(mid)
		zones.append(_make_zone(rng, cell))

	var tries := 0
	while zones.size() < n_zones and tries < n_zones * 12:
		tries += 1
		var cand := Vector2i(rng.randi_range(2, cols - 3), rng.randi_range(2, rows - 3))
		var mag := rng.randi_range(1, 10) * 10
		var overlaps := 0
		for z in zones:
			if _zones_overlap(cand, mag, z.cell, z.magnitude):
				overlaps += 1
		if overlaps > 1:
			continue
		zones.append(_make_zone_with(rng, cand, mag))
	return zones

static func _make_zone(rng: RandomNumberGenerator, cell: Vector2i):
	return _make_zone_with(rng, cell, rng.randi_range(1, 10) * 10)

static func _make_zone_with(rng: RandomNumberGenerator, cell: Vector2i, magnitude: int):
	var zone: Variant = ZoneDefinitionScript.new()
	zone.cell = cell
	zone.magnitude = magnitude
	match rng.randi_range(0, 3):
		0: zone.type = ZoneDefinitionScript.Type.DAMAGE
		1: zone.type = ZoneDefinitionScript.Type.ATTACK_SPEED
		2: zone.type = ZoneDefinitionScript.Type.RANGE
		_: zone.type = ZoneDefinitionScript.Type.SLOW
	return zone

static func _zones_overlap(c1: Vector2i, m1: int, c2: Vector2i, m2: int) -> bool:
	var w1 := GridScript.cell_to_world(c1)
	var w2 := GridScript.cell_to_world(c2)
	return w1.distance_to(w2) < BonusZoneScript.radius_for_magnitude(m1) + BonusZoneScript.radius_for_magnitude(m2)

static func _derive_thresholds(map, _path_len_px: float) -> void:
	map.star1_threshold = GameConstants.TRIALS_STAR_ROUNDS[0]
	map.star2_threshold = GameConstants.TRIALS_STAR_ROUNDS[1]
	map.star3_threshold = GameConstants.TRIALS_STAR_ROUNDS[2]

static func _round_to(value: float, step: int) -> int:
	return int(round(value / float(step))) * step

static func _compute_path(entry: Vector2i, checkpoints: Array, exit: Vector2i, blocked: Dictionary) -> PackedVector2Array:
	return PathfinderScript.compute_full_path(entry, checkpoints, exit, blocked)

static func _path_length(pts: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(pts.size() - 1):
		total += pts[i].distance_to(pts[i + 1])
	return total
