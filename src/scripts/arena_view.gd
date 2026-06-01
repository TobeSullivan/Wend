extends Node2D
class_name ArenaView

# Spectator camera for multi-board matches. Frames ONE board at a time (the others
# are hidden so there's no neighbour bleed): during build/post-match it shows the
# local player's board; during run phase the player can cycle through every board
# (DESIGN: "boards hidden during build phase, visible during run phase").
#
# Only created when num_boards > 1 — solo (campaign / solo PVE) renders exactly as
# before, with no camera. References are untyped to avoid class-name cycles.

const GridScript := preload("res://scripts/grid.gd")

const MARGIN := 0.92  # a little breathing room around the framed board

var coordinator           # MatchCoordinator
var board_containers: Array = []  # Node2D per board, world-positioned
var grid_size: Vector2i
var local_index: int = 0

var _camera: Camera2D
var _spectate_index: int = 0
var _label: Label

func _ready() -> void:
	_camera = Camera2D.new()
	add_child(_camera)
	_camera.make_current()

	var layer := CanvasLayer.new()
	layer.layer = 6
	add_child(layer)
	_label = Label.new()
	_label.position = Vector2(20, 60)
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color(0.8, 0.95, 1.0))
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 4)
	layer.add_child(_label)

	if coordinator != null:
		coordinator.phase_changed.connect(_on_phase_changed)
	_focus(local_index)

func _on_phase_changed(phase: String) -> void:
	# Build and post-match: always show your own board. Run phase: keep whatever
	# the player is spectating (defaults to their board).
	if phase != "run":
		_focus(local_index)
	else:
		_update_label()

func _input(event: InputEvent) -> void:
	if coordinator == null or coordinator.phase != "run":
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var n := board_containers.size()
	match event.keycode:
		KEY_TAB, KEY_RIGHT, KEY_BRACKETRIGHT:
			_focus((_spectate_index + 1) % n)
		KEY_LEFT, KEY_BRACKETLEFT:
			_focus((_spectate_index - 1 + n) % n)

func spectate_next() -> void:
	_focus((_spectate_index + 1) % board_containers.size())

func current_index() -> int:
	return _spectate_index

# Frame board `i`: hide all others, center + zoom-to-fit on it.
func _focus(i: int) -> void:
	_spectate_index = i
	for j in range(board_containers.size()):
		board_containers[j].visible = (j == i)
	var board_px := Vector2(grid_size.x, grid_size.y) * float(GridScript.TILE_SIZE)
	var center: Vector2 = board_containers[i].position + board_px / 2.0
	if _camera != null:
		_camera.position = center
		var vp := get_viewport_rect().size
		var z: float = minf(vp.x / board_px.x, vp.y / board_px.y) * MARGIN
		_camera.zoom = Vector2(z, z)
	_update_label()

func _update_label() -> void:
	if _label == null:
		return
	if coordinator != null and coordinator.phase != "run":
		_label.text = "Your board"
	elif _spectate_index == local_index:
		_label.text = "Your board   [Tab] spectate"
	else:
		_label.text = "Spectating board %d   [Tab] next  [←/→] switch" % (_spectate_index + 1)
