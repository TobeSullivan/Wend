extends CanvasLayer
class_name TutorialCallout

# Tutorial beat presentation (design/CAMPAIGN.md "Tutorial-beat system"). Two forms:
#  • toast — a non-blocking card near the bottom-center (or leaning toward an anchor
#    region), auto-dismissed after a few seconds or on click. Does NOT pause the game.
#  • blocking modal — a dimmed backdrop + centered card + "Got it" button that pauses the
#    tree until acknowledged (single-player pauses; only M1's opener uses this).
# No literal pointer-arrows yet — `anchor` only nudges the toast's screen position.

const UiStyle := preload("res://scripts/ui_style.gd")

const TOAST_SECONDS := 6.0
const CARD_MAX_W := 520.0

signal acknowledged   # emitted when a blocking beat is dismissed (director chains the next)

var _toast: Control = null
var _toast_timer: SceneTreeTimer = null
var _modal: Control = null

func _ready() -> void:
	layer = 50  # above the in-match HUD
	process_mode = Node.PROCESS_MODE_ALWAYS  # button must work while the tree is paused

# Non-blocking callout. `anchor` nudges position; replaces any current toast.
func show_toast(text: String, anchor: String = "") -> void:
	_dismiss_toast()
	var p := _panel_with_text(text)
	_anchor_panel(p, anchor)
	add_child(p)
	_toast = p
	p.gui_input.connect(_on_toast_input)
	_toast_timer = get_tree().create_timer(TOAST_SECONDS)
	_toast_timer.timeout.connect(_dismiss_toast)

# Blocking modal: dim backdrop + card + "Got it". Pauses the tree; resumes + emits
# `acknowledged` on click. Caller must be single-player (pause-safe) — campaign always is.
func show_blocking(text: String) -> void:
	_dismiss_toast()
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP  # swallow clicks meant for the board

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
	if _toast_timer != null and _toast_timer.timeout.is_connected(_dismiss_toast):
		_toast_timer.timeout.disconnect(_dismiss_toast)
	_toast_timer = null
	if _toast != null and is_instance_valid(_toast):
		_toast.queue_free()
	_toast = null

# --- builders ---

func _panel_with_text(text: String) -> PanelContainer:
	var p := PanelContainer.new()
	UiStyle.apply_card(p, 16)
	var m := MarginContainer.new()
	_pad(m, 18)
	p.add_child(m)
	m.add_child(_make_label(text))
	return p

func _make_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(CARD_MAX_W, 0)
	l.add_theme_font_size_override("font_size", 17)
	l.add_theme_color_override("font_color", Color.WHITE)
	return l

func _pad(m: MarginContainer, n: int) -> void:
	m.add_theme_constant_override("margin_left", n)
	m.add_theme_constant_override("margin_right", n)
	m.add_theme_constant_override("margin_top", n)
	m.add_theme_constant_override("margin_bottom", n)

# Position a content-sized panel within the screen. The panel sizes to its content; we pin
# it to an anchor point and grow inward so it never clips off-screen.
func _anchor_panel(p: Control, anchor: String) -> void:
	match anchor:
		"score":  # top-right, under the HUD's score readout
			p.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			p.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			p.grow_vertical = Control.GROW_DIRECTION_END
			p.offset_top = 92
			p.offset_right = -24
		"upgrade_panel":  # right side, by the inspector dock
			p.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
			p.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			p.grow_vertical = Control.GROW_DIRECTION_BOTH
			p.offset_right = -24
		_:  # bottom-center toast (default; covers "board", "tower", "respawn", "zone", "")
			p.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
			p.grow_horizontal = Control.GROW_DIRECTION_BOTH
			p.grow_vertical = Control.GROW_DIRECTION_BEGIN
			p.offset_bottom = -28
