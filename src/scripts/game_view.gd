extends Node2D

const UiLayout := preload("res://scripts/ui_layout.gd")
const GridScript := preload("res://scripts/grid.gd")

var coordinator
var board_containers: Array = []
var grid_size: Vector2i
var local_index: int = 0
var is_pvp: bool = false
var local_build_controller
var tower_drawer
var minimap
var board_names: Array = []

const UiStyle := preload("res://scripts/ui_style.gd")

var _camera: Camera2D
var _spectate_index: int = 0
var _frame: Panel
var _banner: PanelContainer
var _banner_label: Label
var _back_button: Button

const TAP_MOVE_PX := 16.0
var _touches: Dictionary = {}
var _touch_start: Dictionary = {}
var _touch_moved: Dictionary = {}

func _ready() -> void:
	_camera = Camera2D.new()
	add_child(_camera)
	_camera.make_current()

	var layer := CanvasLayer.new()
	layer.layer = 7
	add_child(layer)
	_build_spectate_chrome(layer)

	if coordinator != null:
		coordinator.phase_changed.connect(_on_phase_changed)
	_focus(local_index)

func _build_spectate_chrome(layer: CanvasLayer) -> void:
	var s := UiLayout.scale_factor()

	_frame = Panel.new()
	_frame.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fsb := StyleBoxFlat.new()
	fsb.bg_color = Color(0, 0, 0, 0)
	fsb.draw_center = false
	fsb.border_color = UiStyle.START_BG
	fsb.set_border_width_all(int(6 * s))
	fsb.set_corner_radius_all(0)
	_frame.add_theme_stylebox_override("panel", fsb)
	_frame.visible = false
	layer.add_child(_frame)

	_banner = PanelContainer.new()
	_banner.add_theme_stylebox_override("panel",
		UiStyle.flat_box(UiStyle.START_BG, 16, UiStyle.START_BORDER, 2, true))
	_banner.anchor_left = 0.5
	_banner.anchor_right = 0.5
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.offset_top = 14 * s
	_banner.visible = false
	layer.add_child(_banner)
	var bmargin := MarginContainer.new()
	bmargin.add_theme_constant_override("margin_left", int(18 * s))
	bmargin.add_theme_constant_override("margin_right", int(18 * s))
	bmargin.add_theme_constant_override("margin_top", int(8 * s))
	bmargin.add_theme_constant_override("margin_bottom", int(8 * s))
	_banner.add_child(bmargin)
	_banner_label = Label.new()
	_banner_label.add_theme_font_size_override("font_size", int(18 * s))
	_banner_label.add_theme_color_override("font_color", Color.WHITE)
	_banner_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_banner_label.add_theme_constant_override("outline_size", 3)
	bmargin.add_child(_banner_label)

	_back_button = Button.new()
	_back_button.text = "← Back to your board"
	_back_button.add_theme_font_size_override("font_size", int(16 * s))
	UiStyle.style_flat_button(_back_button, UiStyle.PILL_BG, 16, UiStyle.PILL_BORDER)
	_back_button.anchor_left = 0.5
	_back_button.anchor_right = 0.5
	_back_button.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_back_button.offset_top = 60 * s
	_back_button.visible = false
	_back_button.pressed.connect(func(): focus_board(local_index))
	layer.add_child(_back_button)

func _on_phase_changed(phase: String) -> void:
	if phase != "run":
		_focus(local_index)
	else:
		_update_label()

func focus_board(i: int) -> void:
	if i >= 0 and i < board_containers.size():
		_focus(i)

func refit() -> void:
	_focus(_spectate_index)

func current_index() -> int:
	return _spectate_index

func board_screen_rect() -> Rect2:
	if _camera == null or _spectate_index < 0 or _spectate_index >= board_containers.size():
		return Rect2()
	var board_px := Vector2(grid_size.x, grid_size.y) * float(GridScript.TILE_SIZE)
	var z: float = _camera.zoom.x
	var vp := get_viewport_rect().size
	var origin: Vector2 = board_containers[_spectate_index].position
	var tl: Vector2 = (origin - _camera.position) * z + vp / 2.0
	return Rect2(tl, board_px * z)

func _focus(i: int) -> void:
	_spectate_index = i
	if tower_drawer != null and tower_drawer.has_method("hide_readonly"):
		tower_drawer.hide_readonly()
	for j in range(board_containers.size()):
		board_containers[j].visible = (j == i)
	if _camera == null:
		return
	var board_px := Vector2(grid_size.x, grid_size.y) * float(GridScript.TILE_SIZE)
	var vp := get_viewport_rect().size
	var play := UiLayout.play_rect(is_pvp, vp)
	var z: float = minf(play.size.x / board_px.x, play.size.y / board_px.y) * UiLayout.PLAY_MARGIN
	_camera.zoom = Vector2(z, z)
	var board_center: Vector2 = board_containers[i].position + board_px / 2.0
	var play_center: Vector2 = play.position + play.size / 2.0
	var screen_center: Vector2 = vp / 2.0
	_camera.position = board_center - (play_center - screen_center) / z
	_clamp_camera()
	_update_label()

func _update_label() -> void:
	if _frame == null:
		return
	var spectating: bool = _spectate_index != local_index \
		and coordinator != null and coordinator.phase == "run"
	_frame.visible = spectating
	_banner.visible = spectating
	_back_button.visible = spectating
	if spectating:
		var r := board_screen_rect()
		_frame.position = r.position
		_frame.size = r.size
		_banner_label.text = "Spectating %s" % _name_for(_spectate_index)

func _name_for(i: int) -> String:
	if i >= 0 and i < board_names.size() and String(board_names[i]) != "":
		return board_names[i]
	return "Board %d" % (i + 1)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		_on_key(event)
		return
	if event is InputEventMouseButton:
		_on_mouse_button(event)
		return
	if event is InputEventScreenTouch:
		_on_touch(event)
	elif event is InputEventScreenDrag:
		_on_drag(event)

func _on_mouse_button(e: InputEventMouseButton) -> void:
	if not (e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
		return
	if _spectate_index == local_index:
		return
	if not UiLayout.play_rect(is_pvp, get_viewport_rect().size).has_point(e.position):
		return
	if _over_open_overlay(e.position):
		return
	_spectate_tower_tap(_screen_to_world(e.position))
	get_viewport().set_input_as_handled()

func _on_key(e: InputEventKey) -> void:
	if not e.pressed or e.echo:
		return
	if coordinator == null or coordinator.phase != "run":
		return
	var n := board_containers.size()
	if n <= 1:
		return
	var slot := -1
	if e.keycode >= KEY_1 and e.keycode <= KEY_8:
		slot = e.keycode - KEY_1
	if slot < 0:
		return
	var order := _board_order()
	if slot >= order.size():
		return
	focus_board(order[slot])
	get_viewport().set_input_as_handled()

func _board_order() -> Array:
	var order: Array = [local_index]
	for i in range(board_containers.size()):
		if i != local_index:
			order.append(i)
	return order

func _on_touch(e: InputEventScreenTouch) -> void:
	if e.pressed:
		if not UiLayout.play_rect(is_pvp, get_viewport_rect().size).has_point(e.position):
			return
		if _over_open_overlay(e.position):
			return
		_touches[e.index] = e.position
		_touch_start[e.index] = e.position
		_touch_moved[e.index] = false
	else:
		if not _touches.has(e.index):
			return
		var moved: bool = _touch_moved.get(e.index, false)
		var was_multi: bool = _touches.size() > 1
		_touches.erase(e.index)
		_touch_start.erase(e.index)
		_touch_moved.erase(e.index)
		if _touches.is_empty() and not moved and not was_multi:
			_dispatch_tap(e.position)

func _on_drag(e: InputEventScreenDrag) -> void:
	if not _touches.has(e.index):
		return
	_touches[e.index] = e.position
	if e.position.distance_to(_touch_start.get(e.index, e.position)) > TAP_MOVE_PX:
		_touch_moved[e.index] = true

func _clamp_camera() -> void:
	if _camera == null or board_containers.is_empty():
		return
	var i := _spectate_index
	if i < 0 or i >= board_containers.size():
		return
	var board_px := Vector2(grid_size.x, grid_size.y) * float(GridScript.TILE_SIZE)
	var board_min: Vector2 = board_containers[i].position
	var board_max: Vector2 = board_min + board_px
	var vp := get_viewport_rect().size
	var play := UiLayout.play_rect(is_pvp, vp)
	var z := _camera.zoom.x
	var lo: Vector2 = board_min - (play.position - vp / 2.0) / z
	var hi: Vector2 = board_max - (play.position + play.size - vp / 2.0) / z
	var pos: Vector2 = _camera.position
	if board_px.x * z > play.size.x:
		pos.x = clampf(pos.x, minf(lo.x, hi.x), maxf(lo.x, hi.x))
	if board_px.y * z > play.size.y:
		pos.y = clampf(pos.y, minf(lo.y, hi.y), maxf(lo.y, hi.y))
	_camera.position = pos

func _over_open_overlay(pos: Vector2) -> bool:
	if tower_drawer != null and tower_drawer.covers(pos):
		return true
	if minimap != null and minimap.has_method("covers") and minimap.covers(pos):
		return true
	return false

func _dispatch_tap(screen_pos: Vector2) -> void:
	if _over_open_overlay(screen_pos):
		return
	var world := _screen_to_world(screen_pos)
	if _spectate_index != local_index:
		_spectate_tower_tap(world)
		return
	if local_build_controller == null:
		return
	local_build_controller.handle_tap(world)

func _spectate_tower_tap(world: Vector2) -> void:
	if tower_drawer == null or coordinator == null:
		return
	if _spectate_index < 0 or _spectate_index >= coordinator.boards.size():
		return
	var origin: Vector2 = board_containers[_spectate_index].position
	var cell := GridScript.world_to_cell(world - origin)
	var bc = coordinator.boards[_spectate_index].build_controller
	if bc == null:
		return
	var tower = bc.tower_at_cell(cell)
	if tower != null:
		tower_drawer.show_readonly(tower)
	else:
		tower_drawer.hide_readonly()

func _screen_to_world(s: Vector2) -> Vector2:
	var vp := get_viewport_rect().size
	return _camera.position + (s - vp / 2.0) / _camera.zoom.x
