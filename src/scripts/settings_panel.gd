extends CanvasLayer
class_name SettingsPanel

# Reusable settings overlay (DESIGN_MODES "Settings contents"), openable from both
# the home screen and the pause menu. Reads/writes SaveData and applies changes
# live; saves to disk on close. Has NO Esc handler of its own — whoever opens it
# (pause menu in-match, home screen otherwise) closes it on Esc, so there's a
# single Esc arbiter per context and no input race.

const UiStyle := preload("res://scripts/ui_style.gd")

signal closed

var _root: Control
var _master: HSlider
var _music: HSlider
var _sfx: HSlider
var _master_pct: Label
var _music_pct: Label
var _sfx_pct: Label
var _speed: OptionButton
var _fullscreen: CheckButton
var _resolution: OptionButton
var _damage_numbers: CheckButton

func _ready() -> void:
	layer = 40  # above the pause menu (30)
	process_mode = Node.PROCESS_MODE_ALWAYS  # usable while the tree is paused
	_build_ui()
	_root.visible = false

func is_open() -> bool:
	return _root.visible

func open() -> void:
	_refresh_from_settings()
	_root.visible = true

func close() -> void:
	SaveData.save()
	_root.visible = false
	closed.emit()

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 0)
	# Centre + grow both so it stays centred as it sizes to its content (PRESET_CENTER
	# froze the offsets from the pre-content size — same fix as the pause menu).
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	UiStyle.apply_panel(panel, 12)
	_root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title := _label("Settings", 28, Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	vbox.add_child(_hsep())

	_master = _add_volume_row(vbox, "Master volume")
	_master_pct = _last_pct
	_music = _add_volume_row(vbox, "Music volume")
	_music_pct = _last_pct
	_sfx = _add_volume_row(vbox, "SFX volume")
	_sfx_pct = _last_pct

	vbox.add_child(_hsep())

	_speed = OptionButton.new()
	_speed.add_item("1×", 1)
	_speed.add_item("2×", 2)
	_speed.add_item("3×", 3)
	_speed.item_selected.connect(_on_speed_selected)
	vbox.add_child(_row("Default game speed", _speed))

	_resolution = OptionButton.new()
	for label in SaveData.resolution_labels():
		_resolution.add_item(label)
	_resolution.item_selected.connect(_on_resolution_selected)
	vbox.add_child(_row("Resolution", _resolution))

	_fullscreen = CheckButton.new()
	_fullscreen.toggled.connect(_on_fullscreen_toggled)
	vbox.add_child(_row("Fullscreen", _fullscreen))

	_damage_numbers = CheckButton.new()
	_damage_numbers.toggled.connect(_on_damage_numbers_toggled)
	vbox.add_child(_row("Damage numbers", _damage_numbers))

	vbox.add_child(_hsep())

	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(0, 46)
	back.add_theme_font_size_override("font_size", 18)
	back.pressed.connect(close)
	vbox.add_child(back)

# --- Populate from saved values ---

func _refresh_from_settings() -> void:
	_master.value = float(SaveData.get_setting("master_volume"))
	_music.value = float(SaveData.get_setting("music_volume"))
	_sfx.value = float(SaveData.get_setting("sfx_volume"))
	_update_pct(_master_pct, _master.value)
	_update_pct(_music_pct, _music.value)
	_update_pct(_sfx_pct, _sfx.value)
	_select_by_id(_speed, int(SaveData.get_setting("default_game_speed")))
	_resolution.select(clampi(int(SaveData.get_setting("resolution_index")), 0, SaveData.RESOLUTIONS.size() - 1))
	_fullscreen.button_pressed = bool(SaveData.get_setting("fullscreen"))
	_damage_numbers.button_pressed = bool(SaveData.get_setting("damage_numbers"))

# --- Handlers (apply live) ---

func _on_master_changed(v: float) -> void:
	SaveData.set_setting("master_volume", v)
	_update_pct(_master_pct, v)
	SaveData.apply_audio()

func _on_music_changed(v: float) -> void:
	SaveData.set_setting("music_volume", v)
	_update_pct(_music_pct, v)
	SaveData.apply_audio()

func _on_sfx_changed(v: float) -> void:
	SaveData.set_setting("sfx_volume", v)
	_update_pct(_sfx_pct, v)
	SaveData.apply_audio()

func _on_speed_selected(idx: int) -> void:
	# "Default" speed — applied at match start (see main.gd), not to menus here.
	SaveData.set_setting("default_game_speed", _speed.get_item_id(idx))

func _on_resolution_selected(idx: int) -> void:
	SaveData.set_setting("resolution_index", idx)
	SaveData.apply_display()

func _on_fullscreen_toggled(on: bool) -> void:
	SaveData.set_setting("fullscreen", on)
	SaveData.apply_display()

func _on_damage_numbers_toggled(on: bool) -> void:
	SaveData.set_setting("damage_numbers", on)

# --- UI helpers ---

var _last_pct: Label

func _add_volume_row(parent: VBoxContainer, label_text: String) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.custom_minimum_size = Vector2(220, 0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_last_pct = _label("100%", 16, Color(0.7, 0.9, 1.0))
	_last_pct.custom_minimum_size = Vector2(50, 0)
	_last_pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# Wire after creating the pct label so the handler can update it.
	match label_text:
		"Master volume": slider.value_changed.connect(_on_master_changed)
		"Music volume": slider.value_changed.connect(_on_music_changed)
		"SFX volume": slider.value_changed.connect(_on_sfx_changed)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var name_label := _label(label_text, 16, Color.WHITE)
	name_label.custom_minimum_size = Vector2(150, 0)
	row.add_child(name_label)
	row.add_child(slider)
	row.add_child(_last_pct)
	parent.add_child(row)
	return slider

func _row(label_text: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var name_label := _label(label_text, 16, Color.WHITE)
	name_label.custom_minimum_size = Vector2(150, 0)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	row.add_child(control)
	return row

func _update_pct(label: Label, v: float) -> void:
	label.text = "%d%%" % int(round(v * 100.0))

func _select_by_id(option: OptionButton, id: int) -> void:
	for i in range(option.item_count):
		if option.get_item_id(i) == id:
			option.select(i)
			return

func _hsep() -> HSeparator:
	return HSeparator.new()

func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l
