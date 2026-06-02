extends CanvasLayer
class_name MinimapPanel

# PVP arena minimap (DESIGN_MODES "Arena", DESIGN pillar "Learning through
# defeat"). A TFT/autochess-style panel of all boards, always on screen:
#   - Build phase: opponents are fogged. If you've seen a board on a previous run,
#     its last-seen build shows as dimmed remnants under the fog; otherwise solid
#     fog. Your own board is always clear (you built it).
#   - Run phase: every board is clear/live — this is when you read the leader's maze.
# Click a tile to focus it. During run that drives the spectator camera onto the
# live board; during build, selecting an opponent opens a large fogged "last seen"
# panel so you can study the remnants of their previous build.
#
# Created only for multi-board matches (see map_loader); solo never builds one.

const MinimapTileScript := preload("res://scripts/minimap_tile.gd")
const UiLayout := preload("res://scripts/ui_layout.gd")
const UiStyle := preload("res://scripts/ui_style.gd")

var coordinator                # MatchCoordinator
var boards: Array = []         # BoardState per board
var local_index: int = 0
var grid_size: Vector2i = Vector2i(40, 22)
var arena                      # GameView — for click-to-focus during run

const COLS := 2
const TILE := Vector2(150, 86)  # two columns inside the right rail's arena strip
const GAP := 8.0
const BIG := Vector2(720, 400)

var _tiles: Array = []
var _big  # MinimapTile — untyped to avoid the class-name cycle
var _snapshots: Array = []     # per board: Array of {cell, color}
var _seen: Array = []          # per board: bool
var _selected: int = 0

func _ready() -> void:
	layer = 11  # above the action rail (10) so it shows in the rail's arena strip
	_selected = local_index
	var n := boards.size()
	_snapshots.resize(n)
	_seen.resize(n)
	for i in range(n):
		_snapshots[i] = []
		_seen[i] = (i == local_index)  # your own board is always "seen"
	_build_ui()
	_capture(local_index)
	if coordinator != null:
		coordinator.phase_changed.connect(_on_phase_changed)
		coordinator.board_eliminated.connect(func(_b): _refresh())
	# Your own board updates live as you place/sell during build.
	if boards[local_index].build_controller != null:
		boards[local_index].build_controller.towers_changed.connect(func(_c, _cap): _capture(local_index); _refresh())
	_refresh()

func _build_ui() -> void:
	var vp := get_viewport().get_visible_rect().size
	var n := boards.size()

	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE  # only tiles catch clicks; gaps pass through
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# The minimap occupies the bottom strip of the right rail.
	var region := UiLayout.arena_region(vp)
	var sep := ColorRect.new()  # a top divider so it reads as its own rail section
	sep.color = UiStyle.BORDER
	sep.position = region.position
	sep.size = Vector2(region.size.x, 1)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(sep)

	var start_x := region.position.x + 10.0
	var start_y := region.position.y + 8.0

	var title := Label.new()
	title.text = "ARENA"
	title.position = Vector2(start_x + GAP, start_y)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 3)
	root.add_child(title)

	for i in range(n):
		var col := i % COLS
		var row := i / COLS
		var tile := MinimapTileScript.new()
		tile.custom_minimum_size = TILE
		tile.size = TILE
		tile.position = Vector2(start_x + GAP + col * (TILE.x + GAP), start_y + 24.0 + GAP + row * (TILE.y + GAP))
		tile.mouse_filter = Control.MOUSE_FILTER_STOP
		tile.index = i
		tile.grid_size = grid_size
		tile.entry = boards[i].build_controller.entry_cell
		tile.exit_cell = boards[i].build_controller.exit_cell
		tile.checkpoints = boards[i].build_controller.checkpoint_cells
		tile.clicked.connect(_on_tile_clicked)
		root.add_child(tile)
		_tiles.append(tile)

	# Large "last seen" focus panel (build-phase opponent study), centred over the
	# play rect. Hidden by default.
	var play := UiLayout.play_rect(true, vp)
	_big = MinimapTileScript.new()
	_big.custom_minimum_size = BIG
	_big.size = BIG
	_big.position = play.position + (play.size - BIG) / 2.0
	_big.mouse_filter = Control.MOUSE_FILTER_STOP
	_big.grid_size = grid_size
	_big.visible = false
	_big.clicked.connect(func(_i): _dismiss_focus())
	root.add_child(_big)

# --- Snapshots / fog ---

func _capture(i: int) -> void:
	var arr: Array = []
	var bc = boards[i].build_controller
	if bc != null:
		for t in bc.towers:
			if not is_instance_valid(t):
				continue
			var col := Color(0.7, 0.7, 0.7)
			if t.sprite != null:
				col = t.sprite.modulate
			arr.append({"cell": t.grid_cell, "color": col})
	_snapshots[i] = arr
	_seen[i] = true

func _capture_all() -> void:
	for i in range(boards.size()):
		_capture(i)

func _on_phase_changed(phase: String) -> void:
	# At run start, lock in everyone's current build as the last-seen snapshot
	# (mazes are frozen during the run, so this stays exact all run long).
	if phase == "run":
		_capture_all()
	_refresh()

# --- Interaction ---

func _on_tile_clicked(i: int) -> void:
	_selected = i
	if coordinator != null and coordinator.phase == "run" and arena != null:
		arena.focus_board(i)  # watch the live board in the big spectator view
	_refresh()

func _dismiss_focus() -> void:
	_selected = local_index
	_refresh()

# --- Refresh ---

func _refresh() -> void:
	var phase: String = coordinator.phase if coordinator != null else "build"
	var is_pvp: bool = coordinator != null and coordinator.is_pvp
	for i in range(_tiles.size()):
		var tile = _tiles[i]
		var b = boards[i]
		var is_local := (i == local_index)
		tile.snapshot = _snapshots[i]
		tile.seen = _seen[i]
		tile.fogged = not (is_local or phase == "run")  # opponents fogged during build
		tile.selected = (i == _selected)
		tile.eliminated = b.eliminated
		tile.header = "You" if is_local else "Board %d" % (i + 1)
		if is_pvp:
			tile.subhdr = "OUT" if b.eliminated else "L %d" % b.lives
		else:
			tile.subhdr = ""
		tile.queue_redraw()
	_refresh_big(phase)

func _refresh_big(phase: String) -> void:
	# The big study panel only matters during build, for a seen opponent. During
	# the run the live spectator camera shows the real board instead.
	var show: bool = phase == "build" and _selected != local_index and _seen[_selected]
	_big.visible = show
	if not show:
		return
	_big.index = _selected
	_big.entry = boards[_selected].build_controller.entry_cell
	_big.exit_cell = boards[_selected].build_controller.exit_cell
	_big.checkpoints = boards[_selected].build_controller.checkpoint_cells
	_big.snapshot = _snapshots[_selected]
	_big.seen = true
	_big.fogged = true
	_big.selected = true
	_big.eliminated = boards[_selected].eliminated
	_big.header = "Board %d — last seen (fogged)" % (_selected + 1)
	_big.subhdr = "click to close"
	_big.queue_redraw()
