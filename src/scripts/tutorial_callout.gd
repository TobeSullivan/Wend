extends CanvasLayer
class_name TutorialCallout

const UiStyle := preload("res://scripts/ui_style.gd")

const CARD_MAX_W := 520.0

signal acknowledged

var _toast: Control = null
var _modal: Control = null

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_toast(text: String, anchor: String = "") -> void:
	_dismiss_toast()
	var p := _panel_with_text(text)
	_anchor_panel(p, anchor)
	add_child(p)
	_toast = p
	p.gui_input.connect(_on_toast_input)

func show_blocking(text: String) -> void:
	_dismiss_toast()
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var p := PanelContainer.new()
	UiStyle.apply_card(p, 16)
	center.add_child(p)
	var m := MarginContainer.new()
	_pad(m, 22)
	p.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	m.add_child(v)
	v.add_child(_make_label(text))

	var btn := Button.new()
	btn.text = "Got it"
	btn.add_theme_font_size_override("font_size", 16)
	UiStyle.style_go_button(btn)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(_ack_blocking)
	v.add_child(btn)

	add_child(root)
	_modal = root
	get_tree().paused = true

func _ack_blocking() -> void:
	get_tree().paused = false
	if _modal != null and is_instance_valid(_modal):
		_modal.queue_free()
	_modal = null
	emit_signal("acknowledged")

func _on_toast_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		_dismiss_toast()

func _dismiss_toast() -> void:
	if _toast != null and is_instance_valid(_toast):
		_toast.queue_free()
	_toast = null

func _panel_with_text(text: String) -> PanelContainer:
	var p := PanelContainer.new()
	UiStyle.apply_card(p, 16)
	var m := MarginContainer.new()
	_pad(m, 18)
	p.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	m.add_child(v)
	v.add_child(_make_label(text))
	v.add_child(_make_hint("Tap to dismiss"))
	return p

func _make_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(CARD_MAX_W, 0)
	l.add_theme_font_size_override("font_size", 17)
	l.add_theme_color_override("font_color", Color.WHITE)
	return l

func _make_hint(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return l

func _pad(m: MarginContainer, n: int) -> void:
	m.add_theme_constant_override("margin_left", n)
	m.add_theme_constant_override("margin_right", n)
	m.add_theme_constant_override("margin_top", n)
	m.add_theme_constant_override("margin_bottom", n)

func _anchor_panel(p: Control, anchor: String) -> void:
	match anchor:
		"score":
			p.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			p.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			p.grow_vertical = Control.GROW_DIRECTION_END
			p.offset_top = 92
			p.offset_right = -24
		"upgrade_panel":
			p.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
			p.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			p.grow_vertical = Control.GROW_DIRECTION_BOTH
			p.offset_right = -24
		_:
			p.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
			p.grow_horizontal = Control.GROW_DIRECTION_BOTH
			p.grow_vertical = Control.GROW_DIRECTION_BEGIN
			p.offset_bottom = -28
