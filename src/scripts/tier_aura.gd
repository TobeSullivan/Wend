extends Sprite2D
class_name TierAura

const MotionScript := preload("res://scripts/motion.gd")

const TEX_SIZE := 128
const AURA_H := 48.0
const FOOT_OFFSET := 0.10

const MID_STOP := 0.40
const EDGE_STOP := 0.72

const DIA_LO := 1.5
const DIA_HI := 2.6
const ALPHA_LO := 0.50
const ALPHA_HI := 0.95
const PERIOD_LO := 2.7
const PERIOD_HI := 1.3
const PULSE_SCALE := 1.09
const PULSE_ALPHA := 1.35

var _grad: Gradient
var _base_scale: float = 1.0
var _base_alpha: float = 0.0
var _period: float = PERIOD_LO
var _pulse: Tween

func _ready() -> void:
	z_index = -1
	centered = true
	position = Vector2(0.0, FOOT_OFFSET * AURA_H)
	_grad = Gradient.new()
	_grad.offsets = PackedFloat32Array([0.0, MID_STOP, EDGE_STOP, 1.0])
	_grad.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color.TRANSPARENT, Color.TRANSPARENT])
	var tex := GradientTexture2D.new()
	tex.gradient = _grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = TEX_SIZE
	tex.height = TEX_SIZE
	texture = tex
	visible = false

func set_tier_aura(tier: int, ramp: Array) -> void:
	if tier <= GameConstants.MIN_TIER or ramp.is_empty() or _grad == null:
		_stop_pulse()
		visible = false
		return
	visible = true
	var p := tier_ratio(tier)
	var sample := CosmeticsCatalog.aura_sample(ramp, p)
	var inner: Color = sample["inner"]
	var mid: Color = sample["mid"]
	var fade := Color(mid.r, mid.g, mid.b, 0.0)
	_grad.set_color(0, inner)
	_grad.set_color(1, mid)
	_grad.set_color(2, fade)
	_grad.set_color(3, fade)
	var diameter := lerpf(DIA_LO, DIA_HI, p) * AURA_H
	_base_scale = diameter / float(TEX_SIZE)
	_base_alpha = lerpf(ALPHA_LO, ALPHA_HI, p)
	_period = lerpf(PERIOD_LO, PERIOD_HI, p)
	scale = Vector2.ONE * _base_scale
	modulate.a = _base_alpha
	_start_pulse()

static func tier_ratio(tier: int) -> float:
	var lo := GameConstants.MIN_TIER + 1
	var span := float(GameConstants.MAX_TIER - lo)
	return clampf(float(tier - lo) / maxf(1.0, span), 0.0, 1.0)

func _start_pulse() -> void:
	_stop_pulse()
	if not is_inside_tree() or MotionScript.reduced:
		scale = Vector2.ONE * _base_scale
		modulate.a = _base_alpha
		return
	var half := _period * 0.5
	var peak_scale := _base_scale * PULSE_SCALE
	var peak_alpha := minf(1.0, _base_alpha * PULSE_ALPHA)
	_pulse = create_tween().set_loops()
	_pulse.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse.tween_property(self, "scale", Vector2.ONE * peak_scale, half)
	_pulse.parallel().tween_property(self, "modulate:a", peak_alpha, half)
	_pulse.tween_property(self, "scale", Vector2.ONE * _base_scale, half)
	_pulse.parallel().tween_property(self, "modulate:a", _base_alpha, half)

func _stop_pulse() -> void:
	if _pulse != null and _pulse.is_valid():
		_pulse.kill()
	_pulse = null
