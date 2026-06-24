extends Node2D
class_name Projectile

const SPEED := 900.0
const ARROW_TEX := preload("res://assets/towers/arrow.png")
const ProjectileFXScript := preload("res://scripts/projectile_fx.gd")

var target
var damage: float = 0.0
var is_crit: bool = false
var source_tower: Node2D = null
var tint: Color = Color.WHITE
var fx_id: String = ""

var sprite: Node2D
var _face_travel := true
var _face_offset := PI
var _trail: Dictionary = {}
var _trail_accum := 0.0

func _ready() -> void:
	var cfg := ProjectileFXScript.config_for(fx_id)
	if not is_crit and cfg.has("body"):
		var body: Dictionary = cfg["body"]
		var anim := ProjectileFXScript.make_body(body)
		_face_travel = bool(body.get("rotates", false))
		_face_offset = float(body.get("face_offset", 0.0))
		_trail = cfg.get("trail", {})
		sprite = anim
		add_child(anim)
	else:
		var s := Sprite2D.new()
		s.texture = ARROW_TEX
		if is_crit:
			s.scale = Vector2(0.32, 0.32)
			s.modulate = Color(1.6, 1.3, 0.4, 1.0)
		else:
			s.scale = Vector2(0.22, 0.22)
			s.modulate = tint
		sprite = s
		add_child(s)

func sim_step(delta: float) -> bool:
	if target == null or not is_instance_valid(target) or not target.alive:
		return true

	var to_target: Vector2 = target.position - position
	var dist: float = to_target.length()
	var step := SPEED * delta

	if _face_travel:
		sprite.rotation = to_target.angle() + _face_offset

	if step >= dist:
		var killed := false
		if target.has_method("take_hit"):
			killed = damage >= target.hp
			target.take_hit(damage, is_crit, source_tower)
		if killed and not is_crit and fx_id != "":
			ProjectileFXScript.spawn_impact(get_parent(), target.position, fx_id)
		return true
	position += to_target.normalized() * step
	if not _trail.is_empty():
		_trail_accum += step
		if _trail_accum >= float(_trail["spacing"]):
			_trail_accum = 0.0
			ProjectileFXScript.spawn_trail_puff(get_parent(), position, _trail)
	return false
