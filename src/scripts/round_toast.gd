extends CanvasLayer
class_name RoundToast

# Transient top-center popup showing the gold breakdown at the end of each round.

var round_manager  # RoundManager — untyped to avoid class-name cycle

var _label: Label
var _tween: Tween

func _ready() -> void:
	layer = 7
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 4)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Span the top of the screen, centered.
	_label.anchor_left = 0.0
	_label.anchor_right = 1.0
	_label.offset_top = 70
	_label.modulate.a = 0.0
	add_child(_label)

	if round_manager != null:
		round_manager.round_summary.connect(_on_round_summary)

func _on_round_summary(round_completed: int, kill_gold: int, round_bonus: int, interest: int) -> void:
	_label.text = "Round %d complete   +%dg kills   ·   +%dg round bonus   ·   +%dg interest" % [
		round_completed, kill_gold, round_bonus, interest
	]
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_label.modulate.a = 1.0
	_tween = create_tween()
	_tween.tween_interval(2.5)
	_tween.tween_property(_label, "modulate:a", 0.0, 1.0)
