extends SceneTree

# One-off migration: rescale the 10 hand-authored campaign maps from the dead
# 20x11 board to the locked 23x14 board (2026-06-06 board-size lock). Run headless:
#
#   godot --headless --script res://tools/rescale_campaign.gd
#
# For each mission_*.tres it scales every cell coordinate proportionally, pins the
# new grid_size, scales the medal thresholds by the real maze-length growth (via the
# game's own pathfinder), validates the result, and saves in place. supply_cap /
# round_count / mob_count are intentionally left alone — the economy re-tune for the
# bigger board is a separately-deferred design item. Idempotency note: this assumes
# the .tres are still at 20x11; do not run it twice.

const PathfinderScript := preload("res://scripts/pathfinder.gd")

const OLD := Vector2i(20, 11)
const NEW := Vector2i(25, 14)

func _init() -> void:
	var sx := float(NEW.x) / float(OLD.x)   # 1.15
	var sy := float(NEW.y) / float(OLD.y)   # ~1.2727

	var dir := "res://campaign/"
	var names := []
	for i in range(1, 11):
		names.append("mission_%02d.tres" % i)

	var passed := 0
	var failed := 0
	print("=== Campaign rescale  %dx%d -> %dx%d  (sx=%.4f sy=%.4f) ===" % [OLD.x, OLD.y, NEW.x, NEW.y, sx, sy])

	for n in names:
		var path: String = dir + n
		var map = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if map == null:
			print("  %s  LOAD FAILED" % n)
			failed += 1
			continue

		# --- Snapshot OLD geometry for the threshold ratio ---
		var old_entry: Vector2i = map.entry_cell
		var old_exit: Vector2i = map.exit_cell
		var old_cps: Array = _cells(map.checkpoint_cells)
		var old_blocked := _blocked_from(map.obstacles)
		var old_len := _path_len(PathfinderScript.compute_full_path(old_entry, old_cps, old_exit, old_blocked))

		# --- Scale every coordinate ---
		map.entry_cell = _scale(map.entry_cell, sx, sy)
		map.exit_cell = _scale(map.exit_cell, sx, sy)
		map.entry_cell.x = 0          # snap to the left edge (spawn funnel)
		map.exit_cell.x = NEW.x - 1   # snap to the right edge (despawn funnel)

		var new_cps: Array[Vector2i] = []
		for c in map.checkpoint_cells:
			new_cps.append(_scale(c, sx, sy))
		map.checkpoint_cells = new_cps

		for ob in map.obstacles:
			ob.origin = _clamp_footprint(_scale(ob.origin, sx, sy), ob.footprint)
		for z in map.bonus_zones:
			z.cell = _scale(z.cell, sx, sy)

		map.grid_size = NEW

		# --- New maze length + threshold rescale ---
		var new_blocked := _blocked_from(map.obstacles)
		var new_path := PathfinderScript.compute_full_path(map.entry_cell, _cells(map.checkpoint_cells), map.exit_cell, new_blocked)
		var new_len := _path_len(new_path)
		var ratio := (new_len / old_len) if old_len > 0.0 else 1.0

		var old_thr := [map.bronze_threshold, map.silver_threshold, map.gold_threshold]
		map.bronze_threshold = _round_to(float(map.bronze_threshold) * ratio, 50)
		map.silver_threshold = _round_to(float(map.silver_threshold) * ratio, 50)
		map.gold_threshold = _round_to(float(map.gold_threshold) * ratio, 50)

		# --- Validate ---
		var problems := _validate(map, new_path)
		var status := "PASS" if problems.is_empty() else "FAIL"
		if problems.is_empty():
			passed += 1
		else:
			failed += 1

		# --- Save ---
		var err := ResourceSaver.save(map, path)
		if err != OK:
			status = "SAVE ERR(%d)" % err
			failed += 1

		print("  %-16s %s  entry %s->%s  exit %s->%s  cps=%d  obs=%d  pathx%.3f  thr %s->[%d,%d,%d]" % [
			n, status, old_entry, map.entry_cell, old_exit, map.exit_cell,
			map.checkpoint_cells.size(), map.obstacles.size(), ratio,
			old_thr, map.bronze_threshold, map.silver_threshold, map.gold_threshold])
		for p in problems:
			print("        ! %s" % p)

	print("=== Done: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)

# Proportional scale + clamp into the new board.
func _scale(c: Vector2i, sx: float, sy: float) -> Vector2i:
	return Vector2i(
		clampi(int(round(c.x * sx)), 0, NEW.x - 1),
		clampi(int(round(c.y * sy)), 0, NEW.y - 1))

# Keep a prop's whole footprint on the board after scaling.
func _clamp_footprint(origin: Vector2i, fp: Vector2i) -> Vector2i:
	var w: int = maxi(1, fp.x)
	var h: int = maxi(1, fp.y)
	return Vector2i(
		clampi(origin.x, 0, NEW.x - w),
		clampi(origin.y, 0, NEW.y - h))

func _cells(arr) -> Array:
	var out: Array = []
	for c in arr:
		out.append(c)
	return out

func _blocked_from(obstacles) -> Dictionary:
	var blocked := {}
	for ob in obstacles:
		for c in ob.blocked_cells():
			blocked[c] = true
	return blocked

func _path_len(pts: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(pts.size() - 1):
		total += pts[i].distance_to(pts[i + 1])
	return total

func _round_to(value: float, step: int) -> int:
	return int(round(value / float(step))) * step

# Returns a list of human-readable problems; empty == clean.
func _validate(map, new_path: PackedVector2Array) -> Array:
	var problems: Array = []
	if new_path.is_empty():
		problems.append("path does NOT solve (entry->checkpoints->exit blocked)")

	# Reserved cells: entry, exit, every checkpoint.
	var reserved := {}
	reserved[map.entry_cell] = "entry"
	reserved[map.exit_cell] = "exit"
	for i in range(map.checkpoint_cells.size()):
		reserved[map.checkpoint_cells[i]] = "checkpoint %d" % (i + 1)

	# Obstacle footprints: no two overlap, none sits on a reserved cell.
	var seen := {}
	for ob in map.obstacles:
		for c in ob.blocked_cells():
			if reserved.has(c):
				problems.append("prop '%s' overlaps %s at %s" % [ob.prop_id, reserved[c], c])
			if seen.has(c):
				problems.append("prop '%s' overlaps prop '%s' at %s" % [ob.prop_id, seen[c], c])
			seen[c] = ob.prop_id
	return problems
