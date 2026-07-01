extends CanvasLayer
class_name CountdownOverlay

const UiLayout := preload("res://scripts/ui_layout.gd")
const Motion := preload("res://scripts/motion.gd")

const THRESHOLD := 10

var round_manager

var _label: Label
var _shown_n := -1

func _ready() -> void:
	layer = 10
	_build()
	if round_manager != null:
		round_manager.build_timer_changed.connect(_on_timer)
		round_manager.phase_changed.connect(_on_phase)
	if _current_phase() == "build":
		_apply(_current_time())

func _build() -> void:
	var s := UiLayout.scale_factor()
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", int(160 * s))
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_outline_color", Color("10160c"))
	_label.add_theme_constant_override("outline_size", int(20 * s))
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.anchor_right = 1.0
	_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label.offset_top = 36 * s
	_label.offset_bottom = 246 * s
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.visible = false
	add_child(_label)

func _on_timer(t: float) -> void:
	if _current_phase() == "build":
		_apply(t)

func _on_phase(p: String) -> void:
	if p == "build":
		_apply(_current_time())
	elif _shown_n > 0:
		_flash_go()
	else:
		_hide()

func _apply(t: float) -> void:
	if t > 0.0 and t <= float(THRESHOLD):
		var n := mini(THRESHOLD, int(ceil(t)))
		_label.modulate.a = 1.0
		_label.visible = true
		if n != _shown_n:
			_shown_n = n
			_label.text = str(n)
			_label.add_theme_color_override("font_color", _color_for(n))
			_label.add_theme_color_override("font_outline_color", Color("10160c"))
			Motion.pop(_label, 1.35)
	else:
		_hide()

func _flash_go() -> void:
	_shown_n = -1
	_label.text = "Go"
	_label.modulate.a = 1.0
	_label.add_theme_color_override("font_color", Color("7ce24a"))
	_label.add_theme_color_override("font_outline_color", Color("12300a"))
	_label.visible = true
	Motion.pop(_label, 1.4)
	var tw := _label.create_tween()
	tw.tween_interval(Motion.dur(0.5))
	tw.tween_property(_label, "modulate:a", 0.0, Motion.dur(0.28))
	tw.tween_callback(_hide)

func _hide() -> void:
	_shown_n = -1
	if _label != null:
		_label.visible = false
		_label.modulate.a = 1.0

func _color_for(n: int) -> Color:
	if n <= 3:
		return Color("ff7a45")
	if n <= 5:
		return Color("ffd76a")
	return Color.WHITE

func _current_time() -> float:
	return round_manager.build_time_left if round_manager != null else 0.0

func _current_phase() -> String:
	return round_manager.phase if round_manager != null else ""
