extends Node2D
class_name BuildController

const TowerScript := preload("res://scripts/tower.gd")
const UpgradePanelScript := preload("res://scripts/upgrade_panel.gd")
const LOADED_TEX := preload("res://assets/towers/arrow_box_loaded.png")

const TOWER_RANGE := 320.0
const TOWER_SCALE := 0.25
const NO_BUILD_DIST := 50.0
const TOWER_FOOTPRINT := 100.0
const RANGE_SEGMENTS := 48

# Configured by main.gd before tree entry.
var path: PackedVector2Array
var mobs_array: Array

var towers: Array = []
var _ghost: Sprite2D
var _range_circle: Line2D
var _upgrade_panel  # UpgradePanel — typed at runtime via preload
var _hint_layer: CanvasLayer
var _hint_label: Label

var _build_mode: bool = false

func _ready() -> void:
	_ghost = Sprite2D.new()
	_ghost.texture = LOADED_TEX
	_ghost.scale = Vector2(TOWER_SCALE, TOWER_SCALE)
	_ghost.visible = false
	add_child(_ghost)

	_range_circle = Line2D.new()
	_range_circle.width = 3.0
	_range_circle.closed = true
	var pts := PackedVector2Array()
	for i in range(RANGE_SEGMENTS):
		var a := i * TAU / RANGE_SEGMENTS
		pts.append(Vector2(cos(a), sin(a)) * TOWER_RANGE)
	_range_circle.points = pts
	_range_circle.visible = false
	add_child(_range_circle)

	_upgrade_panel = UpgradePanelScript.new()
	add_child(_upgrade_panel)

	_build_hint_label()
	_refresh_hint()

func _build_hint_label() -> void:
	_hint_layer = CanvasLayer.new()
	_hint_layer.layer = 5
	add_child(_hint_layer)
	_hint_label = Label.new()
	_hint_label.position = Vector2(20, 20)
	_hint_label.add_theme_font_size_override("font_size", 20)
	_hint_label.add_theme_color_override("font_color", Color.WHITE)
	_hint_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint_label.add_theme_constant_override("outline_size", 4)
	_hint_layer.add_child(_hint_label)

func _process(_delta: float) -> void:
	if not _build_mode:
		return
	var mouse := get_global_mouse_position()
	_ghost.position = mouse
	_range_circle.position = mouse
	var valid := _is_valid_placement(mouse)
	if valid:
		_ghost.modulate = Color(0.55, 1.0, 0.55, 0.55)
		_range_circle.default_color = Color(0.4, 1.0, 0.4, 0.7)
	else:
		_ghost.modulate = Color(1.0, 0.4, 0.4, 0.45)
		_range_circle.default_color = Color(1.0, 0.4, 0.4, 0.7)

func _input(event: InputEvent) -> void:
	# Hotkeys
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_B:
				_set_build_mode(not _build_mode)
				return
			KEY_ESCAPE:
				if _build_mode:
					_set_build_mode(false)
				else:
					_upgrade_panel.hide_panel()
				return

	if not (event is InputEventMouseButton and event.pressed):
		return

	var mouse_event: InputEventMouseButton = event
	# Skip world clicks that fall on the upgrade panel — let GUI buttons handle them.
	if _upgrade_panel != null and _upgrade_panel.contains_screen_point(mouse_event.position):
		return

	# Use event.position (click-time position), not get_global_mouse_position()
	# (current position), so the tower lands exactly where the click happened.
	var mouse: Vector2 = mouse_event.position
	if event.button_index == MOUSE_BUTTON_LEFT:
		if _build_mode:
			if _is_valid_placement(mouse):
				_place_tower(mouse)
		else:
			var tower_at := _tower_at(mouse)
			if tower_at != null:
				_upgrade_panel.show_for(tower_at)
			else:
				_upgrade_panel.hide_panel()
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		if _build_mode:
			_set_build_mode(false)
		else:
			_upgrade_panel.hide_panel()
			_sell_tower_at(mouse)

func _set_build_mode(value: bool) -> void:
	_build_mode = value
	_ghost.visible = value
	_range_circle.visible = value
	if value:
		_upgrade_panel.hide_panel()
	_refresh_hint()

func _refresh_hint() -> void:
	if _build_mode:
		_hint_label.text = "BUILD MODE — left-click to place, right-click / Esc to exit"
	else:
		_hint_label.text = "[B] build  |  click tower to upgrade  |  right-click tower to sell"

func _tower_at(pos: Vector2) -> Node2D:
	for t in towers:
		if not is_instance_valid(t):
			continue
		if pos.distance_to(t.position) < TOWER_FOOTPRINT / 2.0:
			return t
	return null

func _is_valid_placement(pos: Vector2) -> bool:
	for i in range(path.size() - 1):
		if _dist_point_segment(pos, path[i], path[i + 1]) < NO_BUILD_DIST:
			return false
	for t in towers:
		if is_instance_valid(t) and pos.distance_to(t.position) < TOWER_FOOTPRINT:
			return false
	return true

static func _dist_point_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var len2 := ab.length_squared()
	if len2 < 0.0001:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / len2, 0.0, 1.0)
	return p.distance_to(a + ab * t)

func _place_tower(pos: Vector2) -> void:
	var tower := TowerScript.new()
	tower.position = pos
	tower.mobs = mobs_array
	get_parent().add_child(tower)
	towers.append(tower)

func _sell_tower_at(pos: Vector2) -> void:
	for i in range(towers.size() - 1, -1, -1):
		var t = towers[i]
		if not is_instance_valid(t):
			towers.remove_at(i)
			continue
		if pos.distance_to(t.position) < TOWER_FOOTPRINT:
			t.queue_free()
			towers.remove_at(i)
			return
