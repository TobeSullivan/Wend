extends CanvasLayer
class_name PauseMenu

const MapResourceScript := preload("res://resources/map_resource.gd")
const SettingsPanelScript := preload("res://scripts/settings_panel.gd")
const Motion := preload("res://scripts/motion.gd")
const UiStyle := preload("res://scripts/ui_style.gd")
const UiLayout := preload("res://scripts/ui_layout.gd")
const StarRatingScript := preload("res://scripts/star_rating.gd")

var build_controller
var round_manager

var is_multiplayer := false
var _settings

var _open := false
var _dim: ColorRect
var _menu_panel: PanelContainer
var _confirm_dim: ColorRect
var _confirm_panel: PanelContainer
var _confirm_label: Label
var _pending_confirm: Callable = Callable()

var _obj_score: Label
var _obj_rows: Array = []

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	is_multiplayer = SceneManager.current_is_multiplayer
	_build_ui()
	_settings = SettingsPanelScript.new()
	add_child(_settings)

func _build_ui() -> void:
	_dim = _make_dim()
	add_child(_dim)

	_menu_panel = _make_centered_panel(Vector2(300, 0))
	add_child(_menu_panel)
	_populate_menu()

	_confirm_dim = _make_dim()
	add_child(_confirm_dim)
	_confirm_panel = _make_centered_panel(Vector2(380, 0))
	add_child(_confirm_panel)
	_populate_confirm()

	_dim.visible = false
	_menu_panel.visible = false
	_confirm_dim.visible = false
	_confirm_panel.visible = false

func _populate_menu() -> void:
	var vbox := _panel_vbox(_menu_panel)

	var title := _label("Paused", 28, Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	vbox.add_child(_spacer(8))

	_build_objectives(vbox)

	vbox.add_child(_menu_button("Resume", _resume, "go"))

	vbox.add_child(_menu_button("Settings", func(): _settings.open()))

	if not is_multiplayer:
		vbox.add_child(_menu_button("Restart", _on_restart))
		vbox.add_child(_menu_button("Quit to Menu", _on_quit, "danger"))
	else:
		vbox.add_child(_menu_button("Quit Match", _on_quit, "danger"))

func _populate_confirm() -> void:
	var vbox := _panel_vbox(_confirm_panel)

	_confirm_label = _label("", 18, Color.WHITE)
	_confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm_label.custom_minimum_size = Vector2(340, 0)
	vbox.add_child(_confirm_label)
	vbox.add_child(_spacer(8))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(row)

	var s := UiLayout.scale_factor()
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.custom_minimum_size = Vector2(140, 44) * s
	cancel.add_theme_font_size_override("font_size", int(16 * s))
	UiStyle.style_menu_button(cancel)
	cancel.pressed.connect(_close_confirm)
	row.add_child(cancel)

	var confirm := Button.new()
	confirm.text = "Confirm"
	confirm.custom_minimum_size = Vector2(140, 44) * s
	confirm.add_theme_font_size_override("font_size", int(16 * s))
	UiStyle.style_danger_button(confirm)
	confirm.pressed.connect(_on_confirm_yes)
	row.add_child(confirm)

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode != KEY_ESCAPE:
		return
	_handle_escape()
	get_viewport().set_input_as_handled()

func _handle_escape() -> void:
	if _settings != null and _settings.is_open():
		_settings.close()
		return
	if _confirm_panel.visible:
		_close_confirm()
		return
	if _open:
		_resume()
		return
	if build_controller != null and build_controller.is_upgrade_panel_open():
		build_controller.close_upgrade_panel()
		return
	if build_controller != null and build_controller.is_build_mode():
		build_controller.exit_build_mode()
		return
	if _can_open():
		_open_menu()

func _can_open() -> bool:
	if round_manager != null and round_manager.match_over:
		return false
	if not is_multiplayer and get_tree().paused:
		return false
	return true

func _open_menu() -> void:
	_open = true
	_refresh_objectives()
	_dim.visible = true
	_menu_panel.visible = true
	Motion.overlay_in(_dim, _menu_panel)
	if not is_multiplayer:
		get_tree().paused = true

func _resume() -> void:
	_open = false
	_close_confirm()
	if not is_multiplayer:
		get_tree().paused = false
	var dim := _dim
	var panel := _menu_panel
	Motion.overlay_out(dim, panel, func():
		dim.visible = false
		panel.visible = false)

func toggle_pause() -> void:
	if _settings != null and _settings.is_open():
		_settings.close()
		return
	if _confirm_panel.visible:
		_close_confirm()
		return
	if _open:
		_resume()
	elif _can_open():
		_open_menu()

func _has_objectives() -> bool:
	return round_manager != null and round_manager.star3_threshold > 0

func _endless() -> bool:
	return round_manager != null and round_manager.coordinator != null and round_manager.coordinator.endless

func _build_objectives(vbox: VBoxContainer) -> void:
	if not _has_objectives():
		return

	var header := _label("Objectives", 18, UiStyle.LABEL_COL)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)

	_obj_score = _label("", 16, Color(1.0, 0.95, 0.7))
	_obj_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_obj_score)

	_obj_rows = [
		{"stars": 1, "threshold": int(round_manager.star1_threshold)},
		{"stars": 2, "threshold": int(round_manager.star2_threshold)},
		{"stars": 3, "threshold": int(round_manager.star3_threshold)},
	]
	for row in _obj_rows:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER

		var stars = StarRatingScript.new()
		stars.configure(int(row.stars), 3, 18.0)
		stars.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.add_child(stars)

		var num := _label(("Round %d" if _endless() else "%d") % int(row.threshold), 16, Color.WHITE)
		hbox.add_child(num)

		var tick := UiStyle.icon_rect("tick", 18)
		tick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.add_child(tick)

		row["hbox"] = hbox
		row["stars_ctrl"] = stars
		row["num"] = num
		row["tick"] = tick
		vbox.add_child(hbox)

	vbox.add_child(_spacer(10))
	_refresh_objectives()

func _refresh_objectives() -> void:
	if not _has_objectives() or _obj_score == null:
		return
	var metric: int = round_manager.star_metric()
	_obj_score.text = ("Round reached: %d" if _endless() else "Your score: %d") % metric
	for row in _obj_rows:
		var reached: bool = metric >= int(row.threshold)
		row.tick.visible = reached
		row.hbox.modulate = Color(1, 1, 1, 1.0) if reached else Color(1, 1, 1, 0.45)

func _ask_confirm(message: String, on_confirm: Callable) -> void:
	_confirm_label.text = message
	_pending_confirm = on_confirm
	_confirm_dim.visible = true
	_confirm_panel.visible = true

func _close_confirm() -> void:
	_confirm_dim.visible = false
	_confirm_panel.visible = false
	_pending_confirm = Callable()

func _on_confirm_yes() -> void:
	var cb := _pending_confirm
	_close_confirm()
	if cb.is_valid():
		cb.call()

func _on_restart() -> void:
	_ask_confirm("Restart this mission? Your progress will be lost.",
		func(): SceneManager.restart_current_match())

func _on_quit() -> void:
	_ask_confirm(_quit_message(), func(): SceneManager.leave_match_to_home(_current_damage()))

func _current_damage() -> int:
	return round_manager.total_damage_dealt if round_manager != null else 0

func _quit_message() -> String:
	if not is_multiplayer:
		return "Quit to the main menu? Your score so far is saved."
	if _is_pvp():
		return "Quit the match? You will be eliminated and your lives will leave the pool."
	return "Quit the match? Your score will not be posted."

func _is_pvp() -> bool:
	var map = SceneManager.pending_map
	return map != null and map.mode == MapResourceScript.Mode.PVP

func _make_dim() -> ColorRect:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	return dim

func _make_centered_panel(min_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = min_size * UiLayout.scale_factor()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = 0.0
	panel.offset_top = 0.0
	panel.offset_right = 0.0
	panel.offset_bottom = 0.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	UiStyle.apply_card(panel, 18)
	return panel

func _panel_vbox(panel: PanelContainer) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	return vbox

func _menu_button(text: String, on_pressed: Callable, role := "menu") -> Button:
	var b := Button.new()
	var s := UiLayout.scale_factor()
	b.text = text
	b.custom_minimum_size = Vector2(220 * s, 48 * s)
	b.add_theme_font_size_override("font_size", int(18 * s))
	match role:
		"go": UiStyle.style_go_button(b)
		"danger": UiStyle.style_danger_button(b)
		_: UiStyle.style_menu_button(b)
	b.pressed.connect(on_pressed)
	return b

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", int(font_size * UiLayout.scale_factor()))
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	return l
