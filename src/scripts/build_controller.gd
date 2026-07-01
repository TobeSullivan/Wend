extends Node2D
class_name BuildController

const TowerScript := preload("res://scripts/tower.gd")
const GridScript := preload("res://scripts/grid.gd")
const PathfinderScript := preload("res://scripts/pathfinder.gd")
const UiLayout := preload("res://scripts/ui_layout.gd")
const MergeFxScript := preload("res://scripts/merge_fx.gd")
const LOADED_TEX := preload("res://assets/towers/arrow_box_loaded.png")

const TOWER_SCALE := 0.12
const RANGE_SEGMENTS := 48

const OFFSCREEN_PAD := 160.0
const DRAG_THRESHOLD := 8.0
const ARM_LIFT := Vector2(0.0, -6.0)

signal towers_changed(count: int, cap: int)
signal tower_selected(tower)
signal selection_cleared
signal build_pending(cell, cost: int, affordable: bool)
signal build_pending_cleared

var mobs_array: Array
var entry_cell: Vector2i
var exit_cell: Vector2i
var checkpoint_cells: Array
var max_towers: int = 50
var grid_size: Vector2i = Vector2i(GridScript.COLS, GridScript.ROWS)
var round_manager
var interactive: bool = true
var tower_drawer
var minimap
var road_renderer

const NetProtocolScript := preload("res://net/net_protocol.gd")
var net = null
var seat: int = 0

var towers: Array = []
var blocked: Dictionary = {}

var tower_skin_tex: Texture2D = null
var proj_tint: Color = Color.WHITE
var fx_id: String = ""
var aura_ramp: Array = []

var _ghost: Sprite2D
var _ghost_range: Line2D
var _sel_range: Line2D
var _selected_tower

var _build_mode: bool = false
var _current_path: PackedVector2Array = PackedVector2Array()
var _projected_path: PackedVector2Array = PackedVector2Array()
var _show_projected: bool = false

const _NO_CELL := Vector2i(0x7fffffff, 0x7fffffff)
var _last_ghost_cell: Vector2i = _NO_CELL
var _last_ghost_valid: bool = false
var _pending_cell: Vector2i = _NO_CELL
var _touch_mode: bool = false

# Merge interaction state.
var _armed: bool = false
var _drag_tower = null
var _dragging: bool = false
var _drag_mouse_start: Vector2 = Vector2.ZERO

func _ready() -> void:
	z_index = -10

	if interactive:
		_ghost = Sprite2D.new()
		if tower_skin_tex != null:
			_ghost.texture = tower_skin_tex
			var gfit := TOWER_SCALE * float(LOADED_TEX.get_width()) / float(maxi(1, tower_skin_tex.get_width()))
			_ghost.scale = Vector2(gfit, gfit)
		else:
			_ghost.texture = LOADED_TEX
			_ghost.scale = Vector2(TOWER_SCALE, TOWER_SCALE)
		_ghost.visible = false
		add_child(_ghost)

		_ghost_range = Line2D.new()
		_ghost_range.width = 2.0
		_ghost_range.closed = true
		_ghost_range.visible = false
		_ghost_range.points = _circle_points(GameConstants.TOWER_BASE_RANGE)
		add_child(_ghost_range)

		_sel_range = Line2D.new()
		_sel_range.width = 4.0
		_sel_range.closed = true
		_sel_range.visible = false
		_sel_range.default_color = Color("aee9ff")
		_sel_range.z_index = 2
		add_child(_sel_range)

		_touch_mode = DisplayServer.is_touchscreen_available()

		if round_manager != null:
			round_manager.phase_changed.connect(_on_phase_changed)
	else:
		set_process(false)
		set_process_input(false)

	recompute_path()
	emit_signal("towers_changed", towers.size(), max_towers)

func _process(_delta: float) -> void:
	if not _build_mode or _touch_mode:
		return
	if _supply_full():
		if _ghost != null:
			_ghost.visible = false
		if _ghost_range != null:
			_ghost_range.visible = false
		if _show_projected:
			_show_projected = false
			_refresh_road_preview()
		return
	if _ghost != null and not _ghost.visible:
		_ghost.visible = true
		_ghost_range.visible = true
		_last_ghost_cell = _NO_CELL
	var cell := GridScript.world_to_cell(get_global_mouse_position())
	var world := GridScript.cell_to_world(cell)
	_ghost.position = world
	_ghost_range.position = world

	if cell != _last_ghost_cell:
		_last_ghost_cell = cell
		_last_ghost_valid = _is_valid_placement(cell)
		if _last_ghost_valid:
			_compute_projected(cell)

	_apply_ghost_color(_last_ghost_valid)

func _apply_ghost_color(valid: bool) -> void:
	if _ghost == null or _ghost_range == null:
		return
	if valid:
		_ghost.modulate = Color(0.55, 1.0, 0.55, 0.6)
		_ghost_range.default_color = Color(0.4, 1.0, 0.4, 0.6)
		_show_projected = true
	else:
		_ghost.modulate = Color(1.0, 0.4, 0.4, 0.45)
		_ghost_range.default_color = Color(1.0, 0.4, 0.4, 0.6)
		_show_projected = false
	_refresh_road_preview()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B:
			_set_build_mode(not _build_mode)
			return
		if _handle_merge_key(event.keycode):
			return

	if _touch_mode:
		return

	# Mouse drag (merge): track motion / release of a grabbed tower.
	if event is InputEventMouseMotion and _drag_tower != null:
		_update_drag()
		return
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _drag_tower != null:
		_end_drag()
		return

	if not (event is InputEventMouseButton and event.pressed):
		return

	var mouse_event: InputEventMouseButton = event
	var is_pvp: bool = round_manager != null and round_manager.coordinator != null and round_manager.coordinator.is_pvp
	if not UiLayout.play_rect(is_pvp, get_viewport_rect().size).has_point(mouse_event.position):
		return
	if tower_drawer != null and tower_drawer.covers(mouse_event.position):
		return
	if minimap != null and minimap.has_method("covers") and minimap.covers(mouse_event.position):
		return

	var cell := GridScript.world_to_cell(get_global_mouse_position())

	if event.button_index == MOUSE_BUTTON_LEFT:
		if _build_mode:
			if not _in_build_phase():
				return
			var existing := _tower_at_cell(cell)
			if existing != null:
				if existing.tier == GameConstants.MIN_TIER and _attempt_build_merge(cell):
					_relay_build_merge(cell)
					_log_action({"type": "build_merge", "cell": cell})
					if not mouse_event.shift_pressed:
						_set_build_mode(false)
				return
			if not _is_valid_placement(cell):
				return
			if not round_manager.can_afford(GameConstants.TOWER_COST):
				return
			round_manager.spend(GameConstants.TOWER_COST)
			_place_tower(cell)
			_relay_place(cell)
			if not mouse_event.shift_pressed:
				_set_build_mode(false)
		else:
			var tower_at := _tower_at_cell(cell)
			if tower_at != null:
				# Begin a potential drag-to-merge; resolves to a plain select on release.
				_set_armed(false)
				_begin_drag(tower_at)
			else:
				_clear_selection()
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		if _build_mode:
			_set_build_mode(false)
		else:
			_set_armed(false)
			_clear_selection()
			if _in_build_phase():
				if _sell_tower_at_cell(cell):
					_relay_sell(cell)

# --- Merge: keyboard / controller (tap-to-arm) ---

func _handle_merge_key(keycode: int) -> bool:
	if _selected_tower == null or not is_instance_valid(_selected_tower):
		return false
	if not _in_build_phase():
		return false
	match keycode:
		KEY_SPACE, KEY_ENTER:
			_set_armed(not _armed)
			return true
		KEY_ESCAPE:
			if _armed:
				_set_armed(false)
				return true
		KEY_UP:
			return _merge_dir(Vector2i(0, -1))
		KEY_DOWN:
			return _merge_dir(Vector2i(0, 1))
		KEY_LEFT:
			return _merge_dir(Vector2i(-1, 0))
		KEY_RIGHT:
			return _merge_dir(Vector2i(1, 0))
	return false

func _merge_dir(dir: Vector2i) -> bool:
	if _selected_tower == null or not is_instance_valid(_selected_tower):
		return false
	var src_cell: Vector2i = _selected_tower.grid_cell
	var target: Vector2i = src_cell + dir
	if _armed:
		if _try_merge(src_cell, target):
			_set_armed(false)
		else:
			_reject_nudge()
		return true
	var t := _tower_at_cell(target)
	if t != null:
		_select_tower(t)
	return true

func _set_armed(value: bool) -> void:
	_armed = value and _selected_tower != null and is_instance_valid(_selected_tower)
	if _selected_tower != null and is_instance_valid(_selected_tower):
		var home := GridScript.cell_to_world(_selected_tower.grid_cell)
		_selected_tower.position = home + ARM_LIFT if _armed else home
		_selected_tower.scale = Vector2(1.06, 1.06) if _armed else Vector2.ONE

func _reject_nudge() -> void:
	if _selected_tower == null or not is_instance_valid(_selected_tower):
		return
	var base := GridScript.cell_to_world(_selected_tower.grid_cell) + ARM_LIFT
	var tw: Tween = _selected_tower.create_tween()
	tw.tween_property(_selected_tower, "position", base + Vector2(-5, 0), 0.05)
	tw.tween_property(_selected_tower, "position", base + Vector2(5, 0), 0.05)
	tw.tween_property(_selected_tower, "position", base, 0.05)

# --- Merge: mouse drag ---

func _begin_drag(tower) -> void:
	_drag_tower = tower
	_dragging = false
	_drag_mouse_start = get_global_mouse_position()

func _update_drag() -> void:
	if _drag_tower == null or not is_instance_valid(_drag_tower):
		_drag_tower = null
		return
	var gm := get_global_mouse_position()
	if not _dragging and gm.distance_to(_drag_mouse_start) > DRAG_THRESHOLD:
		_dragging = true
		_drag_tower.z_index = 12
	if _dragging:
		_drag_tower.position = gm

func _end_drag() -> void:
	var dt = _drag_tower
	_drag_tower = null
	if dt == null or not is_instance_valid(dt):
		return
	if _dragging:
		_dragging = false
		dt.z_index = 0
		var drop_cell := GridScript.world_to_cell(get_global_mouse_position())
		if not _try_merge(dt.grid_cell, drop_cell):
			dt.position = GridScript.cell_to_world(dt.grid_cell)
	else:
		# No real drag: treat as a click-select.
		_select_tower(dt)

# --- Merge: core ---

func _try_merge(src_cell: Vector2i, dst_cell: Vector2i) -> bool:
	if not _in_build_phase():
		return false
	if abs(src_cell.x - dst_cell.x) + abs(src_cell.y - dst_cell.y) != 1:
		return false
	var src := _tower_at_cell(src_cell)
	var dst := _tower_at_cell(dst_cell)
	if src == null or dst == null:
		return false
	if not dst.can_merge_with(src):
		return false
	_do_merge(src, dst)
	_relay_merge(src_cell, dst_cell)
	_log_action({"type": "merge", "src": src_cell, "dst": dst_cell})
	return true

func _attempt_build_merge(cell: Vector2i) -> bool:
	var t := _tower_at_cell(cell)
	if t == null or not is_instance_valid(t) or t.tier != GameConstants.MIN_TIER:
		return false
	if round_manager == null or not round_manager.can_afford(GameConstants.TOWER_COST):
		return false
	round_manager.spend(GameConstants.TOWER_COST)
	_apply_build_merge(t)
	return true

func _apply_build_merge(t) -> void:
	t.total_invested += GameConstants.TOWER_COST
	t.set_tier(t.tier + 1)
	t.play_merge_juice()
	MergeFxScript.poof(get_parent(), t.position, t.aura_poof_color())
	_select_tower(t)
	emit_signal("towers_changed", towers.size(), max_towers)

func apply_remote_build_merge(cell: Vector2i) -> bool:
	var t := _tower_at_cell(cell)
	if t == null or not is_instance_valid(t) or t.tier != GameConstants.MIN_TIER:
		return false
	if round_manager != null:
		round_manager.net_spend(GameConstants.TOWER_COST)
	_apply_build_merge(t)
	return true

func _do_merge(src, dst) -> void:
	var src_cell: Vector2i = src.grid_cell
	dst.position = GridScript.cell_to_world(dst.grid_cell)
	dst.absorb(src)
	dst.play_merge_juice()
	var ramp_col: Color = dst.aura_poof_color()
	MergeFxScript.poof(get_parent(), dst.position, ramp_col)
	MergeFxScript.hole(get_parent(), GridScript.cell_to_world(src_cell))
	_remove_tower_node(src)
	_armed = false
	_select_tower(dst)
	emit_signal("towers_changed", towers.size(), max_towers)

func _remove_tower_node(t) -> void:
	var idx := towers.find(t)
	if idx == -1:
		return
	if t == _selected_tower:
		_selected_tower = null
	blocked.erase(t.grid_cell)
	towers.remove_at(idx)
	t.queue_free()
	recompute_path()
	_last_ghost_cell = _NO_CELL

func _set_build_mode(value: bool) -> void:
	if value and (not _in_build_phase() or _supply_full()):
		return
	_build_mode = value
	var show_ghost: bool = value and not _touch_mode and not _supply_full()
	if _ghost != null:
		_ghost.visible = show_ghost
	if _ghost_range != null:
		_ghost_range.visible = show_ghost
	_last_ghost_cell = _NO_CELL
	if value:
		_ghost_range.points = _circle_points(GameConstants.TOWER_BASE_RANGE)
		_clear_selection()
	else:
		_show_projected = false
		_refresh_road_preview()
		_clear_pending()

func toggle_build_mode() -> void:
	_set_build_mode(not _build_mode)

func handle_tap(world_pos: Vector2) -> void:
	if not interactive:
		return
	_touch_mode = true
	_tap_cell(GridScript.world_to_cell(world_pos))

func tower_at_cell(cell: Vector2i):
	return _tower_at_cell(cell)

func _tap_cell(cell: Vector2i) -> void:
	var t := _tower_at_cell(cell)
	if t != null:
		_clear_pending()
		_select_tower(t)
		return
	if not _in_build_phase():
		return
	if _pending_cell != _NO_CELL and cell == _pending_cell:
		confirm_pending_build()
	elif _is_valid_placement(cell):
		_clear_selection()
		_set_pending(cell)
	else:
		_clear_pending()

func confirm_pending_build() -> void:
	if _pending_cell == _NO_CELL or not _in_build_phase():
		return
	var cell := _pending_cell
	if not _is_valid_placement(cell):
		_clear_pending()
		return
	if round_manager == null or not round_manager.can_afford(GameConstants.TOWER_COST):
		return
	round_manager.spend(GameConstants.TOWER_COST)
	_place_tower(cell)
	_relay_place(cell)
	_clear_pending()

func cancel_pending_build() -> void:
	_clear_pending()

func sell_selected_tower() -> void:
	if _selected_tower == null or not is_instance_valid(_selected_tower):
		return
	if not _in_build_phase():
		return
	var cell: Vector2i = _selected_tower.grid_cell
	if _sell_tower_at_cell(cell):
		_relay_sell(cell)

func _set_pending(cell: Vector2i) -> void:
	_pending_cell = cell
	var world := GridScript.cell_to_world(cell)
	if _ghost != null:
		_ghost.position = world
		_ghost.visible = true
	if _ghost_range != null:
		_ghost_range.position = world
		_ghost_range.visible = true
	var valid := _is_valid_placement(cell)
	if valid:
		_compute_projected(cell)
	_apply_ghost_color(valid)
	var afford: bool = round_manager != null and round_manager.can_afford(GameConstants.TOWER_COST)
	emit_signal("build_pending", cell, GameConstants.TOWER_COST, valid and afford)

func _clear_pending() -> void:
	if _pending_cell == _NO_CELL:
		return
	_pending_cell = _NO_CELL
	if _ghost != null:
		_ghost.visible = false
	if _ghost_range != null:
		_ghost_range.visible = false
	_show_projected = false
	_refresh_road_preview()
	emit_signal("build_pending_cleared")

func _select_tower(tower: Node2D) -> void:
	if _selected_tower != null and _selected_tower != tower and is_instance_valid(_selected_tower):
		_selected_tower.set_selected(false)
	_selected_tower = tower
	if is_instance_valid(_selected_tower):
		_selected_tower.set_selected(true)
		if _sel_range != null:
			_sel_range.points = _circle_points(_selected_tower.get_range())
			_sel_range.position = _selected_tower.position
			_sel_range.visible = true
	emit_signal("tower_selected", tower)

func _clear_selection() -> void:
	if _sel_range != null:
		_sel_range.visible = false
	if _selected_tower != null and is_instance_valid(_selected_tower):
		_selected_tower.set_selected(false)
	if _selected_tower != null:
		_selected_tower = null
		emit_signal("selection_cleared")

func is_build_mode() -> bool:
	return _build_mode

func is_upgrade_panel_open() -> bool:
	return _selected_tower != null

func close_upgrade_panel() -> void:
	_clear_selection()

func exit_build_mode() -> void:
	_set_build_mode(false)

func _in_build_phase() -> bool:
	return round_manager == null or round_manager.phase == "build"

func _on_phase_changed(phase: String) -> void:
	if phase == "run" and _build_mode:
		_set_build_mode(false)
	if road_renderer != null:
		road_renderer.set_chevrons_visible(phase == "build")

func _tower_at_cell(cell: Vector2i) -> Node2D:
	for t in towers:
		if not is_instance_valid(t):
			continue
		if t.grid_cell == cell:
			return t
	return null

func _relay_supply() -> bool:
	return round_manager != null and round_manager.coordinator != null and round_manager.coordinator.is_coop_relay

func _supply_full() -> bool:
	if _relay_supply():
		return round_manager.coordinator.shared_supply_full()
	return towers.size() >= max_towers

func _is_valid_placement(cell: Vector2i) -> bool:
	if _supply_full():
		return false
	if cell.x < 0 or cell.y < 0 or cell.x >= grid_size.x or cell.y >= grid_size.y:
		return false
	if blocked.has(cell):
		return false
	if cell == entry_cell or cell == exit_cell:
		return false
	for cp in checkpoint_cells:
		if cell == cp:
			return false
	var trial: Dictionary = blocked.duplicate()
	trial[cell] = true
	var trial_path := PathfinderScript.compute_full_path(entry_cell, checkpoint_cells, exit_cell, trial)
	return not trial_path.is_empty()

func bot_place_tower(cell: Vector2i) -> bool:
	if not _is_valid_placement(cell):
		return false
	if round_manager == null or not round_manager.can_afford(GameConstants.TOWER_COST):
		return false
	round_manager.spend(GameConstants.TOWER_COST)
	_place_tower(cell)
	return true

func _place_tower(cell: Vector2i) -> void:
	var tower := TowerScript.new()
	tower.grid_cell = cell
	tower.position = GridScript.cell_to_world(cell)
	tower.mobs = mobs_array
	tower.board = round_manager
	tower.total_invested = GameConstants.TOWER_COST
	tower.skin_tex = tower_skin_tex
	tower.proj_tint = proj_tint
	tower.fx_id = fx_id
	tower.aura_ramp = aura_ramp
	get_parent().add_child(tower)
	towers.append(tower)
	blocked[cell] = true
	recompute_path()
	_last_ghost_cell = _NO_CELL
	emit_signal("towers_changed", towers.size(), max_towers)
	_log_action({"type": "place", "cell": cell})

func _sell_tower_at_cell(cell: Vector2i) -> bool:
	for i in range(towers.size() - 1, -1, -1):
		var t = towers[i]
		if not is_instance_valid(t):
			towers.remove_at(i)
			continue
		if t.grid_cell == cell:
			if t == _selected_tower:
				_clear_selection()
			var refund := int(floor(t.total_invested * GameConstants.SELL_REFUND_RATE))
			if round_manager != null:
				round_manager.refund(refund)
			blocked.erase(t.grid_cell)
			t.queue_free()
			towers.remove_at(i)
			recompute_path()
			_last_ghost_cell = _NO_CELL
			emit_signal("towers_changed", towers.size(), max_towers)
			_log_action({"type": "sell", "cell": cell})
			return true
	return false

func _log_action(action: Dictionary) -> void:
	if round_manager != null and round_manager.coordinator != null:
		round_manager.coordinator.log_input(seat, action)

func _relay_place(cell: Vector2i) -> void:
	if net != null:
		net.submit_local_input(NetProtocolScript.build_input_place(seat, cell))

func _relay_sell(cell: Vector2i) -> void:
	if net != null:
		net.submit_local_input(NetProtocolScript.build_input_sell(seat, cell))

func _relay_merge(src: Vector2i, dst: Vector2i) -> void:
	if net != null:
		net.submit_local_input(NetProtocolScript.build_input_merge(seat, src, dst))

func _relay_build_merge(cell: Vector2i) -> void:
	if net != null:
		net.submit_local_input(NetProtocolScript.build_input_build_merge(seat, cell))

func apply_remote_place(cell: Vector2i) -> void:
	if not _is_valid_placement(cell):
		return
	if round_manager != null:
		round_manager.net_spend(GameConstants.TOWER_COST)
	_place_tower(cell)

func apply_remote_sell(cell: Vector2i) -> void:
	_sell_tower_at_cell(cell)

func apply_remote_merge(src: Vector2i, dst: Vector2i) -> bool:
	if abs(src.x - dst.x) + abs(src.y - dst.y) != 1:
		return false
	var s := _tower_at_cell(src)
	var d := _tower_at_cell(dst)
	if s == null or d == null or not d.can_merge_with(s):
		return false
	_do_merge(s, d)
	return true

func recompute_path() -> void:
	_current_path = PathfinderScript.compute_orthogonal_path(entry_cell, checkpoint_cells, exit_cell, blocked)
	if road_renderer != null:
		road_renderer.set_path(current_path_world())

func _refresh_road_preview() -> void:
	if road_renderer == null:
		return
	if _show_projected and _projected_path.size() >= 2:
		road_renderer.set_preview(_extend_offscreen(_projected_path))
	else:
		road_renderer.clear_preview()

func current_path_world() -> PackedVector2Array:
	return _extend_offscreen(_current_path)

func _extend_offscreen(p: PackedVector2Array) -> PackedVector2Array:
	if p.size() < 2:
		return p
	var first: Vector2 = p[0]
	var last: Vector2 = p[p.size() - 1]
	var board_w: float = float(grid_size.x * GridScript.TILE_SIZE)
	var out := PackedVector2Array()
	out.append(Vector2(0.0, first.y))
	out.append_array(p)
	out.append(Vector2(board_w, last.y))
	return out

func _compute_projected(cell: Vector2i) -> void:
	var trial: Dictionary = blocked.duplicate()
	trial[cell] = true
	_projected_path = PathfinderScript.compute_orthogonal_path(entry_cell, checkpoint_cells, exit_cell, trial)

static func _circle_points(radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(RANGE_SEGMENTS):
		var a := i * TAU / RANGE_SEGMENTS
		pts.append(Vector2(cos(a), sin(a)) * radius)
	return pts
