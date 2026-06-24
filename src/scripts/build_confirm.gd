extends CanvasLayer
class_name BuildConfirm

const UiLayout := preload("res://scripts/ui_layout.gd")
const UiStyle := preload("res://scripts/ui_style.gd")

var build_controller

var _prompt: HBoxContainer
var _prompt_label: Label
var _confirm_button: Button

func _ready() -> void:
	layer = 10
	var s := UiLayout.scale_factor()

	_prompt = HBoxContainer.new()
	_prompt.add_theme_constant_override("separation", int(10 * s))
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_prompt.offset_bottom = -18 * s
	_prompt.visible = false
	add_child(_prompt)

	_prompt_label = Label.new()
	_prompt_label.add_theme_font_size_override("font_size", int(16 * s))
	_prompt_label.add_theme_color_override("font_color", Color("d9ffe0"))
	_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prompt.add_child(_prompt_label)

	_confirm_button = _chip("Build", _on_confirm, UiStyle.START_BG)
	_prompt.add_child(_confirm_button)
	_prompt.add_child(_chip("Cancel", _on_cancel, UiStyle.SELL_BG))

	if build_controller != null:
		build_controller.build_pending.connect(_on_build_pending)
		build_controller.build_pending_cleared.connect(_on_build_pending_cleared)

func _chip(text: String, cb: Callable, bg: Color) -> Button:
	var s := UiLayout.scale_factor()
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 54 * s)
	b.add_theme_font_size_override("font_size", int(16 * s))
	UiStyle.style_flat_button(b, bg, 16, UiStyle.CHIP_BORDER)
	b.pressed.connect(cb)
	return b

func _on_build_pending(_cell, cost: int, affordable: bool) -> void:
	_prompt.visible = true
	_prompt_label.text = "Build here · %dg" % cost
	_confirm_button.disabled = not affordable

func _on_build_pending_cleared() -> void:
	_prompt.visible = false

func _on_confirm() -> void:
	if build_controller != null:
		build_controller.confirm_pending_build()

func _on_cancel() -> void:
	if build_controller != null:
		build_controller.cancel_pending_build()
