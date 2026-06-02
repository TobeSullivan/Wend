extends Node2D

# The match camera, present in EVERY mode (solo gets one now too). It fits the
# focused board into the reserved play rect (screen minus the top bar / right rail /
# left dock) rather than letting the board fill the whole screen — which is what
# made the HUD overlap placeable tiles. Build / post-match frames the local board;
# during the run phase the player can focus any board (driven by clicking the arena
# minimap). Replaces the old arena_view.gd. References are untyped to avoid the
# class-name cycle pitfall noted in project memory.

const UiLayout := preload("res://scripts/ui_layout.gd")
const GridScript := preload("res://scripts/grid.gd")

var coordinator                   # MatchCoordinator
var board_containers: Array = []  # Node2D per board, world-positioned
var grid_size: Vector2i
var local_index: int = 0
var is_pvp: bool = false

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
	var play := UiLayout.play_rect(is_pvp, get_viewport_rect().size)
	_label.position = play.position + Vector2(14, 10)
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color(0.8, 0.95, 1.0))
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 4)
	layer.add_child(_label)

	if coordinator != null:
		coordinator.phase_changed.connect(_on_phase_changed)
	_focus(local_index)

func _on_phase_changed(phase: String) -> void:
	# Build / post-match: always your own board. Run: keep whoever is being watched.
	if phase != "run":
		_focus(local_index)
	else:
		_update_label()

# Public entry for the arena minimap: frame board `i` in the big view.
func focus_board(i: int) -> void:
	if i >= 0 and i < board_containers.size():
		_focus(i)

func current_index() -> int:
	return _spectate_index

# Frame board `i`: hide the others (no neighbour bleed) and fit it into the play rect.
func _focus(i: int) -> void:
	_spectate_index = i
	for j in range(board_containers.size()):
		board_containers[j].visible = (j == i)
	if _camera == null:
		return
	var board_px := Vector2(grid_size.x, grid_size.y) * float(GridScript.TILE_SIZE)
	var vp := get_viewport_rect().size
	var play := UiLayout.play_rect(is_pvp, vp)
	var z: float = minf(play.size.x / board_px.x, play.size.y / board_px.y) * UiLayout.PLAY_MARGIN
	_camera.zoom = Vector2(z, z)
	# Place the board's centre at the play-rect centre on screen. A Camera2D centres
	# its position at the viewport centre, so shift by (play_centre - viewport_centre)/z.
	var board_center: Vector2 = board_containers[i].position + board_px / 2.0
	var play_center: Vector2 = play.position + play.size / 2.0
	var screen_center: Vector2 = vp / 2.0
	_camera.position = board_center - (play_center - screen_center) / z
	_update_label()

func _update_label() -> void:
	if _label == null:
		return
	if _spectate_index == local_index or (coordinator != null and coordinator.phase != "run"):
		_label.text = ""
	else:
		_label.text = "Spectating Board %d" % (_spectate_index + 1)
