extends CanvasLayer
class_name BoardsPicker


const UiStyle := preload("res://scripts/ui_style.gd")
const UiLayout := preload("res://scripts/ui_layout.gd")
const Motion := preload("res://scripts/motion.gd")

var coordinator
var game_view

var _open := false
var _dim: ColorRect
var _panel: PanelContainer

func _ready() -> void:
	layer = 8
	_build_ui()
	_dim.visible = false
	_panel.visible = false

func _build_ui() -> void:
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.5)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_dim_input)
	add_child(_dim)

	_panel = _make_panel()
	add_child(_panel)
	_populate()

func _make_panel() -> PanelContainer:
	var s := UiLayout.scale_factor()
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(300 * s, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", UiStyle.dock_box())
	return panel

func _populate() -> void:
	var s := UiLayout.scale_factor()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", int(20 * s))
	margin.add_theme_constant_override("margin_right", int(20 * s))
	margin.add_theme_constant_override("margin_top", int(16 * s))
	margin.add_theme_constant_override("margin_bottom", int(16 * s))
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", int(8 * s))
	margin.add_child(vbox)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", int(10 * s))
	var title := _label("BOARDS", 18, Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var hint := _label("Esc to close", 12, UiStyle.LABEL_COL)
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(hint)
	vbox.add_child(head)
	vbox.add_child(_sep(s))

	var n := _board_count()
	var local: int = _local_index()
	var order: Array = [local]
	for i in range(n):
		if i != local:
			order.append(i)
	for slot in range(order.size()):
		var board_i: int = order[slot]
		vbox.add_child(_player_row(slot + 1, board_i, board_i == local))

func _player_row(hotkey: int, board_i: int, is_you: bool) -> Button:
	var s := UiLayout.scale_factor()
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 44 * s)
	b.focus_mode = Control.FOCUS_NONE
	if is_you:
		UiStyle.style_flat_button(b, UiStyle.START_BG, 12, UiStyle.START_BORDER, 2, true, 8, 6)
	else:
		UiStyle.style_flat_button(b, UiStyle.CHIP_BG, 12, UiStyle.CHIP_BORDER, 2, true, 8, 6)
	b.pressed.connect(func(): _jump(board_i))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(10 * s))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(row)

	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(26 * s, 26 * s)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge_bg := UiStyle.START_BORDER if is_you else UiStyle.CHIP_BORDER
	badge.add_theme_stylebox_override("panel", UiStyle.flat_box(badge_bg, 7, Color(0, 0, 0, 0.0), 0, false))
	var badge_lbl := _label("%d" % hotkey, 15, Color.WHITE)
	badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(badge_lbl)
	row.add_child(badge)

	var avatar := PanelContainer.new()
	avatar.custom_minimum_size = Vector2(28 * s, 28 * s)
	avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar.add_theme_stylebox_override("panel", UiStyle.flat_box(UiStyle.DOCK_BORDER, 14, UiStyle.PILL_BORDER, 2, false))
	row.add_child(avatar)

	var name_txt := _name_for(board_i)
	if is_you:
		name_txt += "  (you)"
	var name_lbl := _label(name_txt, 16, Color.WHITE)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(name_lbl)

	var chev := _label("›", 22, UiStyle.LABEL_COL)
	chev.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(chev)

	return b

func toggle() -> void:
	if _open:
		close()
	else:
		open()

func open() -> void:
	if _open:
		return
	_open = true
	_dim.visible = true
	_panel.visible = true
	var vp := get_viewport().get_visible_rect().size
	var play := UiLayout.play_rect(false, vp)
	var center: Vector2 = play.position + play.size * 0.5
	_panel.reset_size()
	_panel.position = center - _panel.size * 0.5
	Motion.overlay_in(_dim, _panel)

func close() -> void:
	if not _open:
		return
	_open = false
	var dim := _dim
	var panel := _panel
	Motion.overlay_out(dim, panel, func():
		dim.visible = false
		panel.visible = false)

func is_open() -> bool:
	return _open

func _jump(board_i: int) -> void:
	if game_view != null and game_view.has_method("focus_board"):
		game_view.focus_board(board_i)
	close()

func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close()
	elif event is InputEventScreenTouch and event.pressed:
		close()

func _input(event: InputEvent) -> void:
	if not _open:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()

func _board_count() -> int:
	if coordinator != null and coordinator.get("boards") != null:
		return coordinator.boards.size()
	return 1

func _local_index() -> int:
	if game_view != null and "local_index" in game_view:
		return int(game_view.local_index)
	return 0

func _name_for(board_i: int) -> String:
	if coordinator != null and coordinator.get("board_names") != null:
		var names = coordinator.board_names
		if board_i >= 0 and board_i < names.size() and String(names[board_i]) != "":
			return String(names[board_i])
	return "Board %d" % (board_i + 1)

func _sep(s: float) -> Control:
	var line := ColorRect.new()
	line.color = Color("1c2414")
	line.custom_minimum_size = Vector2(0, maxf(1.0, s))
	return line

func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", int(font_size * UiLayout.scale_factor()))
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	return l
