extends Node2D
class_name DamageNumber

const DURATION := 1.5
const RISE_PX := 64.0
const FADE_START_FRAC := 0.6  # stays fully opaque for first 60% of lifetime

var _elapsed: float = 0.0
var _start_y: float = 0.0
var _label: Label

func setup(amount: float, is_crit: bool, world_pos: Vector2) -> void:
	# Spawn above the mob sprite (mob sprite is ~40px rendered, centered on mob.position).
	position = world_pos + Vector2(randf_range(-12.0, 12.0), -36.0)
	# Capture the anchor y here — _ready may have already fired (if add_child
	# happened before setup) and seen the wrong default position.
	_start_y = position.y
	_label = Label.new()
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 4)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if is_crit:
		_label.text = "%d!" % int(round(amount))
		_label.add_theme_font_size_override("font_size", 24)
		_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	else:
		_label.text = "%d" % int(round(amount))
		_label.add_theme_font_size_override("font_size", 16)
		_label.add_theme_color_override("font_color", Color.WHITE)
	var w := 90.0
	_label.size = Vector2(w, 30.0)
	_label.position = Vector2(-w / 2.0, -22.0)
	add_child(_label)

func _ready() -> void:
	z_index = 10  # above towers and mobs

func _process(delta: float) -> void:
	_elapsed += delta
	var t: float = _elapsed / DURATION
	if t >= 1.0:
		queue_free()
		return
	position.y = _start_y - RISE_PX * t
	if _label != null:
		if t <= FADE_START_FRAC:
			_label.modulate.a = 1.0
		else:
			var fade_t: float = (t - FADE_START_FRAC) / (1.0 - FADE_START_FRAC)
			_label.modulate.a = 1.0 - fade_t
