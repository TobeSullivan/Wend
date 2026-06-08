extends CanvasLayer
class_name RoundToast

# Transient top-center popup showing the gold breakdown at the end of each round.

const Motion := preload("res://scripts/motion.gd")

var round_manager  # RoundManager — untyped to avoid class-name cycle

const REST_TOP := 70.0   # resting Y; the toast drops from a touch above this
const DROP_FROM := 26.0  # how far above REST_TOP it arms before dropping in
const HOLD := 2.2        # seconds held at rest before it leaves

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
	_label.offset_top = REST_TOP
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

	# Arm before reveal (JUICE): set the pre-entrance state before the first animated frame
	# so the resting frame never flashes. Drops from a touch above on the arrive curve while
	# fading in a hair quicker, holds, then leaves (faster than it came, drifting back up).
	_label.offset_top = REST_TOP - DROP_FROM
	_label.modulate.a = 0.0
	_tween = create_tween()
	# Arrive: drop on the arrive curve (linear method tween + arrive_ease inside, so the
	# easing isn't applied twice), fading in a hair quicker in parallel.
	var drop := _tween.tween_method(
		func(p: float): _label.offset_top = lerpf(REST_TOP - DROP_FROM, REST_TOP, Motion.arrive_ease(p)),
		0.0, 1.0, Motion.dur(Motion.M))
	drop.set_trans(Tween.TRANS_LINEAR)
	Motion.settle(_tween.parallel().tween_property(_label, "modulate:a", 1.0, Motion.dur(Motion.S)))
	# Hold, then leave (faster than it arrived, drifting back up as it fades).
	_tween.chain().tween_interval(HOLD)
	Motion.leave(_tween.tween_property(_label, "offset_top", REST_TOP - DROP_FROM, Motion.dur(Motion.S)))
	Motion.leave(_tween.parallel().tween_property(_label, "modulate:a", 0.0, Motion.dur(Motion.S)))
