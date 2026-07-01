extends CanvasLayer
class_name LeaderboardPanel

const UiLayout := preload("res://scripts/ui_layout.gd")
const UiStyle := preload("res://scripts/ui_style.gd")
const Motion := preload("res://scripts/motion.gd")
const PlayerIdentity := preload("res://scripts/player_identity.gd")

var coordinator
var boards: Array = []
var local_index: int = 0
var grid_size: Vector2i = Vector2i(25, 16)
var arena

var _panel: Panel
var _rows_box: VBoxContainer
var _open: bool = false
var _tween: Tween
var _row_nodes: Dictionary = {}

func _ready() -> void:
	layer = 11
	_build_ui()
	if coordinator != null:
		coordinator.phase_changed.connect(_refresh.unbind(1))
		coordinator.lives_resolved.connect(_refresh)
		coordinator.board_eliminated.connect(_refresh.unbind(1))
		coordinator.ready_changed.connect(_refresh)
	_refresh()

func _build_ui() -> void:
	var vp := get_viewport().get_visible_rect().size
	var region := UiLayout.minimap_region(vp)
	var s := UiLayout.scale_factor()

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_panel = Panel.new()
	_panel.add_theme_stylebox_override("panel", UiStyle.dock_box())
	_panel.size = region.size
	_panel.position = Vector2(region.position.x - region.size.x, region.position.y)
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

func _ranking() -> Array:
	var arr: Array = []
	for i in range(boards.size()):
		arr.append(i)
	arr.sort_custom(func(a, b):
		var ba = boards[a]
		var bb = boards[b]
		if ba.eliminated != bb.eliminated:
			return not ba.eliminated
		if ba.eliminated and bb.eliminated:
			return coordinator.placement_of(ba) < coordinator.placement_of(bb)
		return _lives_of(ba) > _lives_of(bb)
	)
	return arr

func _lives_of(b) -> int:
	return coordinator.projected_lives(b) if coordinator != null else b.lives

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

	hb.add_child(PlayerIdentity.avatar_box(pname, null, int(22 * s)))

	var name_lbl := _lbl(pname, int(15 * s), Color.WHITE)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hb.add_child(name_lbl)

	var lives_lbl := _lbl("", int(15 * s), Color(1.0, 0.84, 0.55))
	hb.add_child(lives_lbl)

	return {"btn": btn, "rank": rank_lbl, "name": name_lbl, "lives": lives_lbl}

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
		border = Color(1.0, 0.84, 0.55)
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

func _on_row(idx: int) -> void:
	if arena == null or coordinator == null:
		return
	if coordinator.phase == "run":
		arena.focus_board(idx)
		_refresh()
	elif idx == local_index:
		arena.focus_board(local_index)
		_refresh()

func toggle() -> void:
	if _open:
		_close_drawer()
	else:
		_open_drawer()

func is_open() -> bool:
	return _open

func covers(pos: Vector2) -> bool:
	return _open and UiLayout.minimap_region(get_viewport().get_visible_rect().size).has_point(pos)

func _open_drawer() -> void:
	var region := UiLayout.minimap_region(get_viewport().get_visible_rect().size)
	_panel.position.y = region.position.y
	_panel.size = region.size
	_refresh()
	_kill_tween()
	_tween = Motion.arrive_property(_panel, "position:x", region.position.x - region.size.x, region.position.x, Motion.M)
	_open = true

func _close_drawer() -> void:
	var region := UiLayout.minimap_region(get_viewport().get_visible_rect().size)
	_open = false
	_kill_tween()
	_tween = create_tween()
	Motion.leave(_tween.tween_property(_panel, "position:x", region.position.x - region.size.x, Motion.dur(Motion.S)))

func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
