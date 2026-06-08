extends CanvasLayer
class_name LeaderboardPanel

# PVP arena leaderboard (design/VISUAL_SYSTEM.md "PVP UI"). Replaces the old TFT-style
# thumbnail minimap with a toggle-able ranked list — position + player name + lives,
# ranked 1–8 by lives, your row green-highlighted, eliminated rows showing OUT and
# sinking to the bottom. Tapping a name spectates that board (live, during the run).
# Stranger handles truncate with an ellipsis at a fixed row height.
#
# Only the ONE spectated board renders live (the camera frames it); the list is plain
# text, so there are never 8 live thumbnails (the cause of the old 8-board FX crash).
# Created only for multi-board matches (see map_loader); solo never builds one.

const UiLayout := preload("res://scripts/ui_layout.gd")
const UiStyle := preload("res://scripts/ui_style.gd")
const Motion := preload("res://scripts/motion.gd")

var coordinator                # MatchCoordinator
var boards: Array = []         # BoardState per board (index = board index)
var local_index: int = 0
var grid_size: Vector2i = Vector2i(25, 16)
var arena                      # GameView — for tap-to-spectate during run

var _panel: Panel
var _rows_box: VBoxContainer
var _open: bool = false
var _tween: Tween
var _row_nodes: Dictionary = {}   # board idx -> {btn, rank, name, lives}; built once, updated in place

func _ready() -> void:
	layer = 11  # above the action strip (10)
	_build_ui()
	if coordinator != null:
		coordinator.phase_changed.connect(func(_p): _refresh())
		coordinator.lives_resolved.connect(_refresh)
		coordinator.board_eliminated.connect(func(_b): _refresh())
		coordinator.ready_changed.connect(_refresh)
	_refresh()

func _build_ui() -> void:
	var vp := get_viewport().get_visible_rect().size
	var region := UiLayout.minimap_region(vp)
	var s := UiLayout.scale_factor()

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE  # board taps pass through when closed
	add_child(root)

	_panel = Panel.new()
	_panel.add_theme_stylebox_override("panel", UiStyle.dock_box())
	_panel.size = region.size
	_panel.position = Vector2(region.position.x - region.size.x, region.position.y)  # off the left edge
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", int(12 * s))
	margin.add_theme_constant_override("margin_right", int(12 * s))
	margin.add_theme_constant_override("margin_top", int(12 * s))
	margin.add_theme_constant_override("margin_bottom", int(12 * s))
	_panel.add_child(margin)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", int(8 * s))
	margin.add_child(vb)

	var title := Label.new()
	title.text = "LEADERBOARD"
	title.add_theme_font_size_override("font_size", int(16 * s))
	title.add_theme_color_override("font_color", UiStyle.LABEL_COL)
	vb.add_child(title)

	_rows_box = VBoxContainer.new()
	_rows_box.add_theme_constant_override("separation", int(6 * s))
	vb.add_child(_rows_box)

# --- Ranking: active boards first (lives desc), eliminated sink to the bottom
# (better placement above worse). Returns board indices in display order.
func _ranking() -> Array:
	var arr: Array = []
	for i in range(boards.size()):
		arr.append(i)
	arr.sort_custom(func(a, b):
		var ba = boards[a]
		var bb = boards[b]
		if ba.eliminated != bb.eliminated:
			return not ba.eliminated  # active above eliminated
		if ba.eliminated and bb.eliminated:
			# both out: the one eliminated later (better placement) ranks higher
			return coordinator.placement_of(ba) < coordinator.placement_of(bb)
		return _lives_of(ba) > _lives_of(bb)
	)
	return arr

# Lives for ranking/display: the live projection during the run (re-ranks the board
# mid-match), the settled value otherwise.
func _lives_of(b) -> int:
	return coordinator.projected_lives(b) if coordinator != null else b.lives

# While open during the run, re-rank on a light throttle so the projected lives + order
# move mid-match (kills on any board shift the projection but emit no panel signal).
var _poll_accum: float = 0.0
func _process(dt: float) -> void:
	if _open and coordinator != null and coordinator.phase == "run" and not coordinator.match_over:
		_poll_accum += dt
		if _poll_accum >= 0.2:
			_poll_accum = 0.0
			_refresh()

func _refresh() -> void:
	if _rows_box == null:
		return
	# Build the row buttons ONCE; afterwards update them IN PLACE (text + order + style).
	# Rebuilding every poll used to queue_free the button under the cursor mid-click, so
	# taps were silently dropped and spectating felt broken ("click over and over").
	if _row_nodes.is_empty():
		for idx in range(boards.size()):
			var row := _make_row(idx)
			_row_nodes[idx] = row
			_rows_box.add_child(row["btn"])
	var ranking := _ranking()
	for pos in range(ranking.size()):
		var idx: int = ranking[pos]
		_update_row(_row_nodes[idx], pos + 1, idx)
		_rows_box.move_child(_row_nodes[idx]["btn"], pos)

# Build one persistent row (structure only); content + style are set by _update_row.
func _make_row(idx: int) -> Dictionary:
	var s := UiLayout.scale_factor()
	var pname: String = coordinator.name_for(boards[idx]) if coordinator != null else "Board %d" % (idx + 1)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 42 * s)
	btn.pressed.connect(func(): _on_row(idx))

	var hb := HBoxContainer.new()
	hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hb.offset_left = 10 * s
	hb.offset_right = -10 * s
	hb.add_theme_constant_override("separation", int(8 * s))
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(hb)

	var rank_lbl := _lbl("", int(15 * s), UiStyle.LABEL_COL)
	rank_lbl.custom_minimum_size = Vector2(22 * s, 0)
	hb.add_child(rank_lbl)

	var name_lbl := _lbl(pname, int(15 * s), Color.WHITE)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hb.add_child(name_lbl)

	var lives_lbl := _lbl("", int(15 * s), Color(1.0, 0.84, 0.55))
	hb.add_child(lives_lbl)

	return {"btn": btn, "rank": rank_lbl, "name": name_lbl, "lives": lives_lbl}

# Update a persistent row in place: rank, lives, eliminated dimming, and style (your row
# green; the board you're currently spectating gets a gold accent so the tap clearly took).
func _update_row(row: Dictionary, rank: int, idx: int) -> void:
	var b = boards[idx]
	var is_local := (idx == local_index)
	row["rank"].text = "%d" % rank
	row["lives"].text = "OUT" if b.eliminated else "%d" % maxi(0, _lives_of(b))
	row["lives"].add_theme_color_override("font_color", Color(0.95, 0.6, 0.55) if b.eliminated else Color(1.0, 0.84, 0.55))
	row["btn"].modulate = Color(1, 1, 1, 0.5) if b.eliminated else Color(1, 1, 1, 1.0)
	var bg: Color = UiStyle.START_BG if is_local else UiStyle.PILL_BG
	var border: Color = UiStyle.PILL_BORDER
	var bw := 2
	if arena != null and not is_local and arena.current_index() == idx:
		border = Color(1.0, 0.84, 0.55)  # gold accent = currently watching this board
		bw = 3
	UiStyle.style_flat_button(row["btn"], bg, 12, border, bw, false, 0, 0)

func _lbl(text: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if col != Color.WHITE:
		l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

# Tap a row: spectate that board live during the run. During build the HARD RULE keeps
# the camera on your own board, so non-local taps are ignored (your own re-centres).
func _on_row(idx: int) -> void:
	if arena == null or coordinator == null:
		return
	if coordinator.phase == "run":
		arena.focus_board(idx)
		_refresh()  # instant: highlight the row you just tapped (don't wait for the 0.2s poll)
	elif idx == local_index:
		arena.focus_board(local_index)
		_refresh()

# --- Drawer (slide in/out from the left edge) ---

func toggle() -> void:
	if _open:
		_close_drawer()
	else:
		_open_drawer()

func is_open() -> bool:
	return _open

# True when the open drawer covers the screen point (so the board ignores the tap).
func covers(pos: Vector2) -> bool:
	return _open and UiLayout.minimap_region(get_viewport().get_visible_rect().size).has_point(pos)

func _open_drawer() -> void:
	var region := UiLayout.minimap_region(get_viewport().get_visible_rect().size)
	_panel.position.y = region.position.y
	_panel.size = region.size
	_refresh()
	_kill_tween()
	# Arrive on the faithful curve (distance-independent ~11% overshoot — TRANS_BACK over this
	# wide a slide would overshoot far past the rest edge). arrive_property arms `from` itself.
	_tween = Motion.arrive_property(_panel, "position:x", region.position.x - region.size.x, region.position.x, Motion.M)
	_open = true

func _close_drawer() -> void:
	var region := UiLayout.minimap_region(get_viewport().get_visible_rect().size)
	_open = false  # taps pass through immediately while it slides out
	_kill_tween()
	# Leave: accelerate out, quicker than it arrived (M in, S out).
	_tween = create_tween()
	Motion.leave(_tween.tween_property(_panel, "position:x", region.position.x - region.size.x, Motion.dur(Motion.S)))

func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
