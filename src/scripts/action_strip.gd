extends CanvasLayer
class_name ActionStrip

# Floating control clusters (mockup) — NOT a full-width bar. Bottom-left: Pause +
# (desktop) Build toggle. Bottom-centre: the touch build-confirm prompt. Bottom-right:
# (PVP) Map toggle, Speed (non-PVP), Start Round / Ready. Overlaid on the battlefield,
# reserving nothing. Untyped refs avoid the class-name cycle pitfall.

const UiLayout := preload("res://scripts/ui_layout.gd")
const UiStyle := preload("res://scripts/ui_style.gd")

const FF_MULTS := [1.0, 2.0, 3.0]

var round_manager       # RoundManager
var build_controller    # BuildController
var pause_menu          # PauseMenu
var minimap             # MinimapPanel (PVP)

var _ff_index: int = 0
var _last_build_mode: bool = false

var _build_button: Button
var _start_button: Button
var _ff_button: Button
var _minimap_button: Button

var _prompt: Control
var _prompt_label: Label
var _confirm_button: Button

func _ready() -> void:
	layer = 10
	var s := UiLayout.scale_factor()

	# --- Bottom-left cluster: Pause (+ desktop Build) ---
	var cl := HBoxContainer.new()
	cl.add_theme_constant_override("separation", int(10 * s))
	cl.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	cl.grow_vertical = Control.GROW_DIRECTION_BEGIN
	cl.offset_left = 18 * s
	cl.offset_bottom = -18 * s
	add_child(cl)
	cl.add_child(_icon_btn("pause", _on_pause_pressed))
	_build_button = _chip("Build  [B]", _on_build_pressed)
	_build_button.visible = not _is_touch()
	cl.add_child(_build_button)

	# --- Bottom-centre: touch build-confirm prompt (hidden until a preview is parked) ---
	var pc := HBoxContainer.new()
	pc.add_theme_constant_override("separation", int(10 * s))
	pc.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	pc.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pc.grow_vertical = Control.GROW_DIRECTION_BEGIN
	pc.offset_bottom = -18 * s
	pc.visible = false
	add_child(pc)
	_prompt = pc
	_prompt_label = Label.new()
	_prompt_label.add_theme_font_size_override("font_size", int(16 * s))
	_prompt_label.add_theme_color_override("font_color", Color("d9ffe0"))
	_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pc.add_child(_prompt_label)
	_confirm_button = _chip("Build", _on_confirm_build)
	UiStyle.style_flat_button(_confirm_button, UiStyle.START_BG, 16, UiStyle.START_BORDER)
	pc.add_child(_confirm_button)
	pc.add_child(_chip_col("Cancel", _on_cancel_build, UiStyle.SELL_BG))

	# --- Bottom-right cluster: (Map) Speed / Start·Ready ---
	var cr := HBoxContainer.new()
	cr.add_theme_constant_override("separation", int(10 * s))
	cr.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	cr.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	cr.grow_vertical = Control.GROW_DIRECTION_BEGIN
	cr.offset_right = -18 * s
	cr.offset_bottom = -18 * s
	add_child(cr)
	if _is_pvp():
		_minimap_button = _chip("Ranking", _on_minimap_pressed)
		cr.add_child(_minimap_button)
	if not _is_pvp():
		_ff_button = _chip("Speed 1×", _on_ff_pressed)
		cr.add_child(_ff_button)
	_start_button = _start_btn("▶ Start Round", _on_start_pressed)
	cr.add_child(_start_button)

	if build_controller != null:
		build_controller.build_pending.connect(_on_build_pending)
		build_controller.build_pending_cleared.connect(_on_build_pending_cleared)
	if round_manager != null:
		round_manager.phase_changed.connect(func(_p): _refresh_actions(); _apply_time_scale())
		if _is_pvp() and round_manager.coordinator != null:
			round_manager.coordinator.ready_changed.connect(_refresh_actions)
	_refresh_actions()

# --- button factories ---

func _chip(text: String, cb: Callable) -> Button:
	return _chip_col(text, cb, UiStyle.CHIP_BG)

func _chip_col(text: String, cb: Callable, bg: Color) -> Button:
	var s := UiLayout.scale_factor()
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 54 * s)
	b.add_theme_font_size_override("font_size", int(16 * s))
	UiStyle.style_flat_button(b, bg, 16, UiStyle.CHIP_BORDER)
	b.pressed.connect(cb)
	return b

func _icon_btn(icon_name: String, cb: Callable) -> Button:
	var s := UiLayout.scale_factor()
	var b := Button.new()
	b.custom_minimum_size = Vector2(54, 54) * s
	UiStyle.style_flat_button(b, UiStyle.CHIP_BG, 16, UiStyle.CHIP_BORDER)
	# Centre the glyph with a CenterContainer child (reliable centring at any scale).
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(cc)
	var tr := UiStyle.icon_rect(icon_name, int(26 * s))
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(tr)
	b.pressed.connect(cb)
	return b

func _start_btn(text: String, cb: Callable) -> Button:
	var s := UiLayout.scale_factor()
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 64 * s)
	b.add_theme_font_size_override("font_size", int(22 * s))
	UiStyle.style_flat_button(b, UiStyle.START_BG, 16, UiStyle.START_BORDER)
	b.pressed.connect(cb)
	return b

# --- build-confirm prompt ---

func _on_build_pending(_cell, cost: int, affordable: bool) -> void:
	_prompt.visible = true
	_prompt_label.text = "Build here — %dg" % cost
	_confirm_button.disabled = not affordable

func _on_build_pending_cleared() -> void:
	_prompt.visible = false

func _on_confirm_build() -> void:
	if build_controller != null:
		build_controller.confirm_pending_build()

func _on_cancel_build() -> void:
	if build_controller != null:
		build_controller.cancel_pending_build()

# --- actions ---

func _process(_delta: float) -> void:
	if _build_button != null and _build_button.visible and build_controller != null:
		var bm: bool = build_controller.is_build_mode()
		if bm != _last_build_mode:
			_last_build_mode = bm
			_build_button.text = "Exit Build  [B]" if bm else "Build  [B]"

func _on_pause_pressed() -> void:
	if pause_menu != null:
		pause_menu.toggle_pause()

func _on_build_pressed() -> void:
	if build_controller != null:
		build_controller.toggle_build_mode()

func _on_minimap_pressed() -> void:
	if minimap != null:
		minimap.toggle()

func _on_start_pressed() -> void:
	if round_manager == null:
		return
	if _is_pvp():
		var coord = round_manager.coordinator
		coord.set_board_ready(round_manager, not coord.is_board_ready(round_manager))
		_refresh_actions()
	else:
		round_manager.request_start_now()

func _on_ff_pressed() -> void:
	_ff_index = (_ff_index + 1) % FF_MULTS.size()
	_ff_button.text = "Speed %d×" % int(FF_MULTS[_ff_index])
	_apply_time_scale()

func _apply_time_scale() -> void:
	if _is_pvp():
		Engine.time_scale = 1.0
		return
	if round_manager != null and round_manager.phase == "run" and not round_manager.match_over:
		Engine.time_scale = FF_MULTS[_ff_index]
	else:
		Engine.time_scale = 1.0

func _refresh_actions() -> void:
	if round_manager == null:
		return
	var building: bool = round_manager.phase == "build" and not round_manager.match_over
	_start_button.visible = building
	if _build_button != null:
		_build_button.disabled = not building
	if _is_pvp():
		var coord = round_manager.coordinator
		var readied: bool = coord.is_board_ready(round_manager)
		_start_button.text = "%s Ready (%d/%d)" % ["✓" if readied else "○", coord.ready_count(), coord.active_boards().size()]
	else:
		_start_button.text = "▶ Start Round"
	if _ff_button != null:
		_ff_button.text = "Speed %d×" % int(FF_MULTS[_ff_index])

func _is_pvp() -> bool:
	return round_manager != null and round_manager.coordinator != null and round_manager.coordinator.is_pvp

func _is_touch() -> bool:
	return DisplayServer.is_touchscreen_available() or UiLayout.scale_factor() >= 2.0
