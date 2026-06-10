extends Node2D
class_name Projectile

const SPEED := 900.0  # pixels/sec
const ARROW_TEX := preload("res://assets/towers/arrow.png")
const ProjectileFXScript := preload("res://scripts/projectile_fx.gd")

var target  # the Mob this is chasing — untyped (duck-typed .alive/.position/.take_hit)
var damage: float = 0.0
var is_crit: bool = false
var source_tower: Node2D = null  # who fired this — credited with damage/kills on hit
# Equipped projectile/FX recolor (render-only; WHITE = default). Crits keep their gold
# tell regardless, so the crit read never depends on the cosmetic.
var tint: Color = Color.WHITE
# Equipped "proj" FX id (LOCAL board only; "" => plain arrow). Drives the body sprite
# (fireball replaces the arrow) and the impact burst on hit. See projectile_fx.gd.
var fx_id: String = ""

var sprite: Node2D       # visual: a Sprite2D (arrow) or AnimatedSprite2D (body FX)
var _face_travel := true # arrow points along travel; a round body FX (fireball) does not
var _face_offset := PI   # rotation added to the travel angle (arrow art faces west)

func _ready() -> void:
	var cfg := ProjectileFXScript.config_for(fx_id)
	# Crits ALWAYS show the gold arrow tell (not skinned) — never a body FX.
	if not is_crit and cfg.has("body"):
		var body: Dictionary = cfg["body"]
		var anim := ProjectileFXScript.make_body(body)
		_face_travel = bool(body.get("rotates", false))
		_face_offset = float(body.get("face_offset", 0.0))
		sprite = anim
		add_child(anim)
	else:
		var s := Sprite2D.new()
		s.texture = ARROW_TEX
		if is_crit:
			s.scale = Vector2(0.32, 0.32)
			s.modulate = Color(1.6, 1.3, 0.4, 1.0)  # gold tint (crit tell — not skinned)
		else:
			s.scale = Vector2(0.22, 0.22)
			s.modulate = tint
		sprite = s
		add_child(s)

# Driven by BoardState.sim_step on the fixed sim tick (no longer self-_process'd).
# Returns true when finished (landed a hit, or the target left/was freed) — the
# board then removes it from the projectiles array and frees the node. The target's
# `alive` flag is set SYNCHRONOUSLY when a mob exits, so a multi-tick frame never
# resolves a hit on a mob that already despawned (queue_free defers to frame end).
func sim_step(delta: float) -> bool:
	if target == null or not is_instance_valid(target) or not target.alive:
		return true

	var to_target: Vector2 = target.position - position
	var dist: float = to_target.length()
	var step := SPEED * delta

	# Directional projectiles (arrow, ice shard) point along travel via a per-art offset;
	# a round body FX (fireball) reads fine undirected, so it skips rotation.
	if _face_travel:
		sprite.rotation = to_target.angle() + _face_offset

	if step >= dist:
		var killed := false
		if target.has_method("take_hit"):
			# This hit kills iff it drops hp<=0 (the mob then respawns in place). Capture
			# BEFORE take_hit, since the kill resets hp to max.
			killed = damage >= target.hp
			target.take_hit(damage, is_crit, source_tower)
		# Impact burst — ON KILL ONLY, not every hit: per-hit bursts stack on a mob that
		# many towers are pounding and occlude it (noise gate). Crits skip FX so the crit
		# tell stays clean. Render-only, local; no-op without an impact hook.
		if killed and not is_crit and fx_id != "":
			ProjectileFXScript.spawn_impact(get_parent(), target.position, fx_id)
		return true
	position += to_target.normalized() * step
	return false
